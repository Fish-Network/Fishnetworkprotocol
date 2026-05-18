// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Minimal SafeERC20 helper. Reverts on false-return tokens and non-contract addresses.
library SafeERC20 {
    error SafeERC20Failed();
    error SafeERC20NotContract();

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transfer.selector, to, amount));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));
    }

    function _callOptionalReturn(address token, bytes memory data) private {
        uint256 size;
        assembly { size := extcodesize(token) }
        if (size == 0) revert SafeERC20NotContract();

        (bool ok, bytes memory ret) = token.call(data);
        if (!ok) revert SafeERC20Failed();
        if (ret.length > 0 && !abi.decode(ret, (bool))) revert SafeERC20Failed();
    }
}
