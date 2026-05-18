// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {FPCategory, OrganizerMilestone, FPConstants} from "../types/Reputation.sol";
import {Outcome} from "../types/Voting.sol";

interface IReputationModule {
    event PoolAuthorized(uint256 indexed poolId, address indexed pool, uint16 dfBps);
    event DepositRecorded(address indexed user, uint256 indexed poolId, uint256 indexed depositId, uint256 amount, uint64 depositedAt);
    event CapitalFinalized(address indexed user, uint256 indexed poolId, uint256 indexed depositId, uint256 raw);
    event VoteFPMinted(address indexed user, uint256 indexed poolId, uint256 raw);
    event OrganizerMilestoneFired(address indexed organizer, uint256 indexed poolId, OrganizerMilestone milestone, uint256 raw);
    event FPConstantsUpdated();
    event IdempotentReplayIgnored(bytes32 key);

    // Authorization
    function authorizePool(address pool, uint256 poolId, uint16 dfBps) external;

    // Capital path
    function recordDeposit(address user, uint256 poolId, uint256 depositId, uint256 amount, uint64 depositedAt) external;
    function finalizeCapital(address user, uint256 poolId, uint256 depositId, uint64 finalizedAt) external;

    // Vote path (called by VotingModule)
    function mintVoteFP(
        address user,
        uint256 poolId,
        uint64  firstCastAt,
        uint64  roundStart,
        uint64  roundEnd,
        Outcome choice,
        Outcome winning
    ) external;

    // Organizer milestones (called by Pool)
    function mintOrganizerMilestone(address organizer, uint256 poolId, OrganizerMilestone milestone) external;

    // Views
    function getConstants() external view returns (FPConstants memory);
    function isAuthorizedPool(address pool, uint256 poolId) external view returns (bool);

    function factory() external view returns (address);
    function admin() external view returns (address);
}
