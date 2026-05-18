// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {OrganizerMilestone} from "../types/Reputation.sol";

/// @notice Idempotency-key derivations for FP issuance.
library FishKeys {
    function capitalFin(uint256 poolId, uint256 depositId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("FP:capital:fin", poolId, depositId));
    }

    function voteFP(uint256 poolId, address user) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("FP:vote", poolId, user));
    }

    function organizerMilestone(uint256 poolId, OrganizerMilestone m) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("FP:org", poolId, uint8(m)));
    }
}
