// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @notice Minimal EIP-1167 clone deployment helper.
library MinimalClones {
    function clone(address implementation) internal returns (address instance) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, hex"3d602d80600a3d3981f3")
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), hex"5af43d82803e903d91602b57fd5bf3")
            instance := create(0, add(ptr, 0x09), 0x37)
        }
        require(instance != address(0), "CLONE_DEPLOY_FAILED");
    }
}