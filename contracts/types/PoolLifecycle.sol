// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @notice High-level pool lifecycle states.
/// @dev Paused is orthogonal — when entered, the prior state is stored in _prePauseState on the Pool.
enum LifecycleState {
    Draft,
    Open,
    Active,
    Closed,
    Settled,
    Distributed,
    Failed,
    Paused
}

/// @notice Rule used by Pool.closePool() to decide success vs failure.
enum SuccessRule {
    MinContributionReached,
    AnyCapitalRaised,
    FullCapOnly
}
