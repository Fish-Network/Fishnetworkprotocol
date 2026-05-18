// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IVotingModule} from "../interfaces/IVotingModule.sol";
import {IReputationModule} from "../interfaces/IReputationModule.sol";
import {Outcome, Vote} from "../types/Voting.sol";

/// @notice Singleton vote registry keyed by poolId. Owns the per-pool round window and the per-voter Vote record.
contract VotingModule is IVotingModule {
    error NotAdmin();
    error NotFactory();
    error NotAuthorizedPool();
    error ZeroAddress();
    error RoundAlreadyOpen();
    error RoundNotOpen();
    error RoundAlreadyClosed();
    error AlreadyFinalized();
    error NotFinalized();
    error InvalidOutcome();
    error AlreadyClaimed();
    error NoVote();

    struct PoolVoting {
        uint64  roundStart;
        uint64  roundEnd;
        Outcome winning;
        bool    finalized;
    }

    address public override admin;
    address public immutable override factory;
    IReputationModule public immutable reputationModule;

    mapping(uint256 => address)    public authorizedPool;
    mapping(uint256 => PoolVoting) internal _pools;
    mapping(uint256 => mapping(address => Vote)) internal _votes;
    mapping(uint256 => address[])  internal _voterList;
    mapping(uint256 => mapping(address => bool)) internal _inVoterList;
    mapping(uint256 => mapping(address => bool)) internal _fpClaimed;

    modifier onlyAdmin()   { if (msg.sender != admin)   revert NotAdmin();   _; }
    modifier onlyFactory() { if (msg.sender != factory) revert NotFactory(); _; }
    modifier onlyAuthorizedPool(uint256 poolId) {
        if (authorizedPool[poolId] != msg.sender) revert NotAuthorizedPool();
        _;
    }

    constructor(address initialAdmin, address factory_, address reputationModule_) {
        if (initialAdmin == address(0) || factory_ == address(0) || reputationModule_ == address(0)) revert ZeroAddress();
        admin            = initialAdmin;
        factory          = factory_;
        reputationModule = IReputationModule(reputationModule_);
    }

    function authorizePool(address pool, uint256 poolId) external override onlyFactory {
        if (pool == address(0)) revert ZeroAddress();
        authorizedPool[poolId] = pool;
        emit PoolAuthorized(poolId, pool);
    }

    function openRound(uint256 poolId, uint64 roundStart) external override onlyAuthorizedPool(poolId) {
        if (_pools[poolId].roundStart != 0) revert RoundAlreadyOpen();
        _pools[poolId].roundStart = roundStart;
        emit RoundOpened(poolId, roundStart);
    }

    function closeRound(uint256 poolId, uint64 roundEnd) external override onlyAuthorizedPool(poolId) {
        PoolVoting storage p = _pools[poolId];
        if (p.roundStart == 0) revert RoundNotOpen();
        if (p.roundEnd != 0)   revert RoundAlreadyClosed();
        p.roundEnd = roundEnd;
        emit RoundClosed(poolId, roundEnd);
    }

    function castVote(uint256 poolId, address voter, Outcome choice)
        external override onlyAuthorizedPool(poolId)
    {
        if (voter == address(0)) revert ZeroAddress();
        if (choice == Outcome.None) revert InvalidOutcome();
        PoolVoting storage p = _pools[poolId];
        if (p.roundStart == 0) revert RoundNotOpen();
        if (p.roundEnd != 0)   revert RoundAlreadyClosed();

        Vote storage v = _votes[poolId][voter];
        if (v.firstCastAt == 0) v.firstCastAt = uint64(block.timestamp);
        v.lastCastAt = uint64(block.timestamp);
        v.choice = choice;

        if (!_inVoterList[poolId][voter]) {
            _inVoterList[poolId][voter] = true;
            _voterList[poolId].push(voter);
        }
        emit VoteCast(poolId, voter, choice, uint64(block.timestamp));
    }

    function recordWinningOutcome(uint256 poolId, Outcome winning)
        external override onlyAuthorizedPool(poolId)
    {
        PoolVoting storage p = _pools[poolId];
        if (p.finalized) revert AlreadyFinalized();
        // For Failed pools, callers may pass Outcome.None to indicate "no outcome". Accept it.
        p.winning = winning;
        p.finalized = true;
        emit WinningOutcomeRecorded(poolId, winning);
    }

    function claimVoteFP(uint256 poolId) external override {
        PoolVoting storage p = _pools[poolId];
        if (!p.finalized) revert NotFinalized();
        if (_fpClaimed[poolId][msg.sender]) revert AlreadyClaimed();
        Vote storage v = _votes[poolId][msg.sender];
        if (v.firstCastAt == 0) revert NoVote();

        _fpClaimed[poolId][msg.sender] = true;
        // ReputationModule applies idempotency too; double-bookkeeping is intentional.
        reputationModule.mintVoteFP(
            msg.sender,
            poolId,
            v.firstCastAt,
            p.roundStart,
            p.roundEnd,
            v.choice,
            p.winning
        );
        emit VoteFPClaimed(poolId, msg.sender, 0); // raw amount is in the RepModule event
    }

    // Views
    function getVote(uint256 poolId, address voter) external view override returns (Vote memory) {
        return _votes[poolId][voter];
    }
    function getWinning(uint256 poolId) external view override returns (Outcome) { return _pools[poolId].winning; }
    function getRound(uint256 poolId) external view override returns (uint64, uint64, bool) {
        PoolVoting storage p = _pools[poolId];
        return (p.roundStart, p.roundEnd, p.finalized);
    }
    function hasClaimedFP(uint256 poolId, address voter) external view override returns (bool) {
        return _fpClaimed[poolId][voter];
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        admin = newAdmin;
    }
}
