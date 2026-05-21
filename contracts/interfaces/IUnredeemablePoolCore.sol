// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {UnredeemablePoolConfig, UnredeemableModuleSet} from "../types/PoolConfig.sol";
import {Outcome} from "../types/Voting.sol";
import {LifecycleState} from "../types/PoolLifecycle.sol";

interface IUnredeemablePoolCore {
    event PoolInitialized(uint256 indexed poolId, address indexed pool, address acceptedAsset, uint16 dfBps);
    event PoolStateTransitioned(uint256 indexed poolId, LifecycleState previousState, LifecycleState newState);
    event PoolPaused(uint256 indexed poolId, LifecycleState prePauseState);
    event PoolUnpaused(uint256 indexed poolId, LifecycleState restoredState);
    event ReputationCoefficientUpdated(uint256 indexed poolId, uint16 oldBps, uint16 newBps);

    event DepositMade(uint256 indexed poolId, address indexed depositor, uint256 indexed depositId, uint256 amount, uint64 depositedAt);
    event Withdrawn(uint256 indexed poolId, address indexed depositor, uint256 indexed depositId, uint256 amount, uint64 finalizedAt);
    event Refunded(uint256 indexed poolId, address indexed depositor, uint256 indexed depositId, uint256 amount, uint64 finalizedAt);
    event PoolSettled(uint256 indexed poolId, Outcome winningOutcome, uint64 settledAt, uint256 balanceAtSettle, uint256 supplyAtSettle);
    event DistributedTo(uint256 indexed poolId, address indexed depositor, uint256 share);
    event PoolDistributed(uint256 indexed poolId);
    event PoolFailed(uint256 indexed poolId);

    function initialize(
        uint256 poolId,
        UnredeemablePoolConfig calldata config,
        UnredeemableModuleSet calldata modules,
        address organizer,
        uint16  dfBps,
        address factoryAddress
    ) external;

    // Lifecycle
    function setReputationCoefficient(uint16 newBps) external;
    function openContributions() external;
    function activatePool() external;
    function closePool() external;
    function settle(Outcome winningOutcome) external;
    function distribute(uint256 offset, uint256 count) external;
    function pause() external;
    function unpause() external;

    // Capital
    function deposit(uint256 amount, address receiver) external;
    function withdraw(uint256 depositId) external;
    function refund(uint256 depositId) external;
    function claimCapitalFP(uint256 depositId) external;

    // Voting
    function castVote(Outcome choice) external;

    // Views
    function poolId() external view returns (uint256);
    function lifecycleState() external view returns (LifecycleState);
    function organizer() external view returns (address);
    function totalAssetsCommitted() external view returns (uint256);
    function reputationCoefficientBps() external view returns (uint16);
    function getDepositCount(address user) external view returns (uint256);
}
