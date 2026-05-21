// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {UnredeemablePoolConfig} from "../types/PoolConfig.sol";

interface IUnredeemablePoolFactory {
    event PoolCreated(uint256 indexed poolId, address indexed pool, address indexed organizer, address acceptedAsset, uint16 dfBps);
    event PoolOpenRegistered(address indexed organizer, address indexed pool, uint64 lastOpenedAt, uint16 activeCount);
    event PoolFinalizedRegistered(address indexed organizer, address indexed pool, uint16 activeCount);
    event ModulesUpdated(address membership, address voting, address rep, address points, address impl);
    event CooldownUpdated(uint64 newSeconds);
    event MaxActivePoolsUpdated(uint16 newMax);
    event CoefficientBoundsUpdated(uint16 minBps, uint16 maxBps);
    event CreatePauseUpdated(bool paused);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

    function createPool(UnredeemablePoolConfig calldata config, uint16 initialDFBps)
        external
        returns (address pool, uint256 poolId);

    // Called by pool clones
    function registerPoolOpen(address organizer) external;
    function registerPoolFinalized(address organizer) external;

    // Admin
    function setModules(address membership, address voting, address rep, address points, address impl) external;
    function setCooldownDuration(uint64 newSeconds) external;
    function setMaxActivePools(uint16 newMax) external;
    function setCoefficientBounds(uint16 minBps, uint16 maxBps) external;
    function setCreatePaused(bool paused) external;
    function transferAdmin(address newAdmin) external;

    // Views
    function poolById(uint256 poolId) external view returns (address);
    function poolIdByAddress(address pool) external view returns (uint256);
    function activePoolCount(address organizer) external view returns (uint16);
    function lastOpenedAt(address organizer) external view returns (uint64);
    function cooldownDuration() external view returns (uint64);
    function maxActivePoolsPerOrganizer() external view returns (uint16);
    function minCoeffBps() external view returns (uint16);
    function maxCoeffBps() external view returns (uint16);
    function admin() external view returns (address);
}
