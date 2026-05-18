// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {FPCategory} from "../types/Reputation.sol";

interface IReputationPoints {
    event PointsMinted(
        address indexed user,
        uint256 indexed poolId,
        uint256 rawAmount,
        FPCategory category,
        uint256 effectiveDelta,
        uint256 newEffectiveTotal
    );
    event PoolDFLocked(uint256 indexed poolId, uint16 dfBps);
    event MinterAuthorizationUpdated(address indexed minter, bool authorized);
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);

    function mint(address user, uint256 poolId, uint256 rawAmount, FPCategory category) external;
    function lockPoolDF(uint256 poolId, uint16 dfBps) external;

    // Raw getters (pre-DF)
    function getCapitalPoints(address user) external view returns (uint256);
    function getParticipationPoints(address user) external view returns (uint256);
    function getPoolCapital(address user, uint256 poolId) external view returns (uint256);
    function getPoolParticipation(address user, uint256 poolId) external view returns (uint256);

    // Effective (DF-scaled)
    function getTotalPoints(address user) external view returns (uint256);
    function getPoolTotal(address user, uint256 poolId) external view returns (uint256);

    function poolDF(uint256 poolId) external view returns (uint16);
    function poolDFLocked(uint256 poolId) external view returns (bool);

    // Admin
    function setMinter(address minter, bool authorized) external;
    function setAdmin(address newAdmin) external;
    function isMinter(address minter) external view returns (bool);

    function factory() external view returns (address);
    function admin() external view returns (address);
}
