// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {ReputationConfig, UnredeemableModuleSet, UnredeemablePoolConfig} from "../types/UnredeemablePoolTypes.sol";

interface IUnredeemablePoolCore {
    function initialize(
        UnredeemablePoolConfig calldata config,
        ReputationConfig calldata reputationConfig,
        UnredeemableModuleSet calldata modules,
        address factory
    ) external;
}