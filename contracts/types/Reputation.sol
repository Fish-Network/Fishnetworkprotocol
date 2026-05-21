// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @notice Bucket a mint is attributed to. Drives whether it accrues to capitalPoints or participationPoints.
enum FPCategory { Capital, Participation }

/// @notice Which lifecycle milestone is firing the organizer mint.
enum OrganizerMilestone { Open, Settle, Distribute }

/// @notice All governance-mutable scoring constants live in one struct on ReputationModule.
struct FPConstants {
    uint128 baseVote;               // default 1e18
    uint128 accuracyBonus;          // default 2e18
    uint16  earlyEndBps;            // default 3300  (33%)
    uint16  lateStartBps;           // default 8000  (80%)
    uint16  earlyMultBps;           // default 15000 (1.5x)
    uint16  standardMultBps;        // default 10000 (1.0x)
    uint16  lateMultBps;            // default 7500  (0.75x)
    uint128 organizerOpenFP;        // default 1e18
    uint128 organizerSettleFP;      // default 5e18
    uint128 organizerDistributeFP;  // default 25e18
    uint32  capitalDayDivisor;      // default 30
    uint16  minCoeffBps;            // default 1000  (0.1x)
    uint16  maxCoeffBps;            // default 50000 (5.0x)
}
