// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @notice Binary outcome per pool. None = not yet decided.
enum Outcome { None, Yes, No }

/// @notice Per-(pool, voter) vote record.
/// @dev firstCastAt drives timing math; lastCastAt is audit-only.
struct Vote {
    Outcome choice;
    uint64  firstCastAt;
    uint64  lastCastAt;
}
