// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

interface IContributionModule {
    function moduleId() external view returns (bytes32);
}