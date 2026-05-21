// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @notice One row per deposit on a pool. finalizedAt == 0 means still live.
struct Deposit {
    uint128 amount;
    uint64  depositedAt;
    uint64  finalizedAt;
}
