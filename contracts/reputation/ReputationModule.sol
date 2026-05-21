// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IReputationModule} from "../interfaces/IReputationModule.sol";
import {IReputationPoints} from "../interfaces/IReputationPoints.sol";
import {FPCategory, OrganizerMilestone, FPConstants} from "../types/Reputation.sol";
import {Deposit} from "../types/Deposit.sol";
import {Outcome} from "../types/Voting.sol";
import {FishMath} from "../libraries/FishMath.sol";
import {FishKeys} from "../libraries/FishKeys.sol";

/// @notice Formula engine for FP. Mints raw FP into ReputationPoints under FPCategory.Capital or .Participation.
contract ReputationModule is IReputationModule {
    error NotAdmin();
    error NotFactory();
    error NotAuthorizedPool();
    error ZeroAddress();
    error InvalidConfig();
    error DepositAlreadyRecorded(uint256 poolId, uint256 depositId);
    error DepositNotRecorded(uint256 poolId, uint256 depositId);

    address public override admin;
    address public immutable override factory;
    IReputationPoints public immutable reputationPoints;
    address public votingModule;

    FPConstants internal _constants;

    // poolId => authorized Pool address
    mapping(uint256 => address) public authorizedPoolByPoolId;
    // (poolId, depositId) => snapshot
    mapping(uint256 => mapping(uint256 => Deposit)) public deposits;
    // idempotency executed set
    mapping(bytes32 => bool) public executed;

    modifier onlyAdmin()   { if (msg.sender != admin) revert NotAdmin(); _; }
    modifier onlyFactory() { if (msg.sender != factory) revert NotFactory(); _; }
    modifier onlyVotingModule() {
        if (msg.sender != votingModule) revert NotAuthorizedPool();
        _;
    }
    modifier onlyAuthorizedPool(uint256 poolId) {
        if (authorizedPoolByPoolId[poolId] != msg.sender) revert NotAuthorizedPool();
        _;
    }

    constructor(address initialAdmin, address factory_, address reputationPoints_) {
        if (initialAdmin == address(0) || factory_ == address(0) || reputationPoints_ == address(0)) revert ZeroAddress();
        admin            = initialAdmin;
        factory          = factory_;
        reputationPoints = IReputationPoints(reputationPoints_);

        _constants = FPConstants({
            baseVote:               1e18,
            accuracyBonus:          2e18,
            earlyEndBps:            3300,
            lateStartBps:           8000,
            earlyMultBps:           15000,
            standardMultBps:        10000,
            lateMultBps:            7500,
            organizerOpenFP:        1e18,
            organizerSettleFP:      5e18,
            organizerDistributeFP:  25e18,
            capitalDayDivisor:      30,
            minCoeffBps:            1000,
            maxCoeffBps:            50000
        });
    }

    function authorizePool(address pool, uint256 poolId, uint16 dfBps) external override onlyFactory {
        if (pool == address(0)) revert ZeroAddress();
        authorizedPoolByPoolId[poolId] = pool;
        emit PoolAuthorized(poolId, pool, dfBps);
    }

    /// @notice Called by the authorized Pool during openContributions(). Proxies to ReputationPoints.lockPoolDF.
    /// @dev This module is the only registered minter on ReputationPoints, so it's the canonical
    ///      caller for lockPoolDF. The Pool calls through here instead of touching the ledger directly.
    function lockPoolDF(uint256 poolId, uint16 dfBps) external override onlyAuthorizedPool(poolId) {
        reputationPoints.lockPoolDF(poolId, dfBps);
    }

    function isAuthorizedPool(address pool, uint256 poolId) external view override returns (bool) {
        return authorizedPoolByPoolId[poolId] == pool;
    }

    function getConstants() external view override returns (FPConstants memory) {
        return _constants;
    }

    function setConstants(FPConstants calldata newConstants) external onlyAdmin {
        // Light validation only — admin is trusted.
        if (newConstants.earlyEndBps >= newConstants.lateStartBps) revert InvalidConfig();
        if (newConstants.capitalDayDivisor == 0) revert InvalidConfig();
        if (newConstants.minCoeffBps > newConstants.maxCoeffBps) revert InvalidConfig();
        _constants = newConstants;
        emit FPConstantsUpdated();
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        address old = admin;
        admin = newAdmin;
        emit AdminUpdated(old, newAdmin);
    }

    /// @notice One-time wire-up of the singleton VotingModule, called by admin after both contracts are deployed.
    /// @dev Admin can re-call to rotate; the event makes the swap observable to indexers.
    function setVotingModule(address voting) external onlyAdmin {
        if (voting == address(0)) revert ZeroAddress();
        address old = votingModule;
        votingModule = voting;
        emit VotingModuleUpdated(old, voting);
    }

    // ===== Capital path =====

    function recordDeposit(
        address user,
        uint256 poolId,
        uint256 depositId,
        uint256 amount,
        uint64  depositedAt
    ) external override onlyAuthorizedPool(poolId) {
        if (user == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidConfig();
        if (amount > type(uint128).max) revert InvalidConfig();
        Deposit storage d = deposits[poolId][depositId];
        if (d.amount != 0) revert DepositAlreadyRecorded(poolId, depositId);
        d.amount       = uint128(amount);
        d.depositedAt  = depositedAt;
        d.finalizedAt  = 0;
        emit DepositRecorded(user, poolId, depositId, amount, depositedAt);
    }

    function finalizeCapital(
        address user,
        uint256 poolId,
        uint256 depositId,
        uint64  finalizedAt
    ) external override onlyAuthorizedPool(poolId) {
        bytes32 key = FishKeys.capitalFin(poolId, depositId);
        if (executed[key]) { emit IdempotentReplayIgnored(key); return; }

        Deposit storage d = deposits[poolId][depositId];
        if (d.amount == 0) revert DepositNotRecorded(poolId, depositId);
        if (finalizedAt < d.depositedAt) finalizedAt = d.depositedAt;
        d.finalizedAt = finalizedAt;

        uint256 daysHeld = FishMath.daysBetween(d.depositedAt, finalizedAt);
        uint256 raw = (uint256(d.amount) * daysHeld) / uint256(_constants.capitalDayDivisor);

        executed[key] = true;
        if (raw > 0) {
            reputationPoints.mint(user, poolId, raw, FPCategory.Capital);
        }
        emit CapitalFinalized(user, poolId, depositId, raw);
    }

    // ===== Vote path =====

    function mintVoteFP(
        address user,
        uint256 poolId,
        uint64  firstCastAt,
        uint64  roundStart,
        uint64  roundEnd,
        Outcome choice,
        Outcome winning
    ) external override onlyVotingModule {
        bytes32 key = FishKeys.voteFP(poolId, user);
        if (executed[key]) { emit IdempotentReplayIgnored(key); return; }

        uint256 raw = _computeVoteFP(firstCastAt, roundStart, roundEnd, choice, winning);
        executed[key] = true;
        if (raw > 0) {
            reputationPoints.mint(user, poolId, raw, FPCategory.Participation);
        }
        emit VoteFPMinted(user, poolId, raw);
    }

    function _computeVoteFP(
        uint64  firstCastAt,
        uint64  roundStart,
        uint64  roundEnd,
        Outcome choice,
        Outcome winning
    ) internal view returns (uint256) {
        if (roundEnd <= roundStart) return 0;
        uint256 progressBps = (uint256(firstCastAt - roundStart) * 10_000) / uint256(roundEnd - roundStart);
        progressBps = FishMath.clampToBps(progressBps, 10_000);

        uint16 timingMult = FishMath.timingBucket(
            progressBps,
            _constants.earlyEndBps,
            _constants.lateStartBps,
            _constants.earlyMultBps,
            _constants.standardMultBps,
            _constants.lateMultBps
        );

        bool isCorrect = (winning != Outcome.None)
                      && (choice == winning)
                      && (progressBps < _constants.lateStartBps);

        uint256 base = uint256(_constants.baseVote)
                     + (isCorrect ? uint256(_constants.accuracyBonus) : 0);

        return FishMath.applyBps(base, timingMult);
    }

    // ===== Organizer milestone path =====

    function mintOrganizerMilestone(
        address organizer,
        uint256 poolId,
        OrganizerMilestone milestone
    ) external override onlyAuthorizedPool(poolId) {
        bytes32 key = FishKeys.organizerMilestone(poolId, milestone);
        if (executed[key]) { emit IdempotentReplayIgnored(key); return; }

        uint256 raw =
              milestone == OrganizerMilestone.Open       ? uint256(_constants.organizerOpenFP)
            : milestone == OrganizerMilestone.Settle     ? uint256(_constants.organizerSettleFP)
            : milestone == OrganizerMilestone.Distribute ? uint256(_constants.organizerDistributeFP)
            : 0;

        executed[key] = true;
        if (raw > 0) {
            reputationPoints.mint(organizer, poolId, raw, FPCategory.Participation);
        }
        emit OrganizerMilestoneFired(organizer, poolId, milestone, raw);
    }
}
