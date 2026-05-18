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
        admin = newAdmin;
    }

    /// @notice One-time wire-up of the singleton VotingModule, called by admin after both contracts are deployed.
    function setVotingModule(address voting) external onlyAdmin {
        if (voting == address(0)) revert ZeroAddress();
        votingModule = voting;
    }
}
