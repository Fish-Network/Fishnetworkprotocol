// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Outcome, Vote} from "../types/Voting.sol";

interface IVotingModule {
    event PoolAuthorized(uint256 indexed poolId, address indexed pool);
    event RoundOpened(uint256 indexed poolId, uint64 roundStart);
    event RoundClosed(uint256 indexed poolId, uint64 roundEnd);
    event VoteCast(uint256 indexed poolId, address indexed voter, Outcome choice, uint64 castAt);
    event WinningOutcomeRecorded(uint256 indexed poolId, Outcome winning);
    event VoteFPClaimed(uint256 indexed poolId, address indexed voter, uint256 raw);

    // Called by Factory at pool creation.
    function authorizePool(address pool, uint256 poolId) external;

    // Called by the authorized Pool only.
    function openRound(uint256 poolId, uint64 roundStart) external;
    function closeRound(uint256 poolId, uint64 roundEnd) external;
    function castVote(uint256 poolId, address voter, Outcome choice) external;
    function recordWinningOutcome(uint256 poolId, Outcome winning) external;

    // Called by any voter post-settle (or post-fail).
    function claimVoteFP(uint256 poolId) external;

    // Views
    function getVote(uint256 poolId, address voter) external view returns (Vote memory);
    function getWinning(uint256 poolId) external view returns (Outcome);
    function getRound(uint256 poolId) external view returns (uint64 roundStart, uint64 roundEnd, bool finalized);
    function hasClaimedFP(uint256 poolId, address voter) external view returns (bool);

    function factory() external view returns (address);
    function admin() external view returns (address);
}
