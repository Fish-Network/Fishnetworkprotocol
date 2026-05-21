// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @notice Pure helper math for FP scoring.
library FishMath {
    /// @notice value * bps / 10_000.
    function applyBps(uint256 value, uint256 bps) internal pure returns (uint256) {
        return (value * bps) / 10_000;
    }

    /// @notice (end - start) / 1 days, integer truncation. Returns 0 if end <= start.
    function daysBetween(uint64 start, uint64 end) internal pure returns (uint256) {
        if (end <= start) return 0;
        unchecked { return uint256(end - start) / 1 days; }
    }

    /// @notice Min(value, ceil).
    function clampToBps(uint256 value, uint256 ceil) internal pure returns (uint256) {
        return value > ceil ? ceil : value;
    }

    /// @notice Maps a basis-point progress into the matching timing multiplier (in bps).
    function timingBucket(
        uint256 progressBps,
        uint16  earlyEnd,
        uint16  lateStart,
        uint16  earlyMult,
        uint16  standardMult,
        uint16  lateMult
    ) internal pure returns (uint16) {
        if (progressBps <= earlyEnd)  return earlyMult;
        if (progressBps <  lateStart) return standardMult;
        return lateMult;
    }
}
