// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IUnredeemablePoolFactory} from "./interfaces/IUnredeemablePoolFactory.sol";
import {IUnredeemablePoolCore} from "./interfaces/IUnredeemablePoolCore.sol";
import {IMembershipModule} from "./interfaces/IMembershipModule.sol";
import {IVotingModule} from "./interfaces/IVotingModule.sol";
import {IReputationModule} from "./interfaces/IReputationModule.sol";
import {UnredeemablePoolConfig, UnredeemableModuleSet} from "./types/PoolConfig.sol";
import {MinimalClones} from "./libraries/MinimalClones.sol";

contract UnredeemablePoolFactory is IUnredeemablePoolFactory {
    error NotAdmin();
    error NotRegisteredPool();
    error ZeroAddress();
    error InvalidConfig();
    error CreatePaused();
    error DFOutOfBounds();
    error CooldownActive();
    error MaxActiveReached();
    error UnderflowOnFinalize();
    error BoundsInvalid();

    address public override admin;
    address public membershipModule;
    address public votingModule;
    address public reputationModule;
    address public reputationPoints;
    address public poolImplementation;

    // Packed together into one storage slot (8 + 2 + 2 + 2 + 1 = 15 bytes ≤ 32).
    uint64  public override cooldownDuration = 14 days;
    uint16  public override maxActivePoolsPerOrganizer = 3;
    uint16  public override minCoeffBps = 1000;
    uint16  public override maxCoeffBps = 50_000;
    bool    public createPaused_;
    uint256 public nextPoolId = 1;

    mapping(uint256 => address) public override poolById;
    mapping(address => uint256) public override poolIdByAddress;
    mapping(address => uint16)  public override activePoolCount;
    mapping(address => uint64)  public override lastOpenedAt;
    address[] public allPools;

    modifier onlyAdmin() { if (msg.sender != admin) revert NotAdmin(); _; }
    modifier onlyRegisteredPool() { if (poolIdByAddress[msg.sender] == 0) revert NotRegisteredPool(); _; }

    constructor(address initialAdmin) {
        if (initialAdmin == address(0)) revert ZeroAddress();
        admin = initialAdmin;
        // Modules are wired up via setModules() AFTER they're deployed (which depend on this Factory's address).
        // createPool will revert until setModules has been called.
    }

    function createPool(UnredeemablePoolConfig calldata config, uint16 initialDFBps)
        external override returns (address pool, uint256 poolId)
    {
        if (createPaused_) revert CreatePaused();
        if (poolImplementation == address(0)) revert ZeroAddress();
        if (initialDFBps < minCoeffBps || initialDFBps > maxCoeffBps) revert DFOutOfBounds();
        if (config.acceptedAsset == address(0)) revert InvalidConfig();
        if (config.poolCap == 0)                revert InvalidConfig();
        if (bytes(config.name).length == 0)     revert InvalidConfig();

        poolId = nextPoolId++;
        pool   = MinimalClones.clone(poolImplementation);

        poolById[poolId]         = pool;
        poolIdByAddress[pool]    = poolId;
        allPools.push(pool);

        UnredeemableModuleSet memory modules = UnredeemableModuleSet({
            membershipModule: membershipModule,
            votingModule:     votingModule,
            reputationModule: reputationModule,
            reputationPoints: reputationPoints
        });

        IUnredeemablePoolCore(pool).initialize(poolId, config, modules, msg.sender, initialDFBps, address(this));

        IMembershipModule(membershipModule).setPoolMinter(pool, true);
        IVotingModule(votingModule).authorizePool(pool, poolId);
        IReputationModule(reputationModule).authorizePool(pool, poolId, initialDFBps);

        emit PoolCreated(poolId, pool, msg.sender, config.acceptedAsset, initialDFBps);
    }

    function registerPoolOpen(address organizer) external override onlyRegisteredPool {
        uint64 last = lastOpenedAt[organizer];
        if (last != 0 && block.timestamp < uint256(last) + uint256(cooldownDuration)) revert CooldownActive();
        if (activePoolCount[organizer] >= maxActivePoolsPerOrganizer) revert MaxActiveReached();

        lastOpenedAt[organizer] = uint64(block.timestamp);
        activePoolCount[organizer] += 1;
        emit PoolOpenRegistered(organizer, msg.sender, lastOpenedAt[organizer], activePoolCount[organizer]);
    }

    function registerPoolFinalized(address organizer) external override onlyRegisteredPool {
        if (activePoolCount[organizer] == 0) revert UnderflowOnFinalize();
        activePoolCount[organizer] -= 1;
        emit PoolFinalizedRegistered(organizer, msg.sender, activePoolCount[organizer]);
    }

    // ===== Admin =====

    function setModules(address membership, address voting, address rep, address points, address impl)
        external override onlyAdmin
    {
        _setModules(membership, voting, rep, points, impl);
    }

    function _setModules(address membership, address voting, address rep, address points, address impl) internal {
        if (membership == address(0) || voting == address(0) || rep == address(0) || points == address(0) || impl == address(0))
            revert ZeroAddress();
        membershipModule   = membership;
        votingModule       = voting;
        reputationModule   = rep;
        reputationPoints   = points;
        poolImplementation = impl;
        emit ModulesUpdated(membership, voting, rep, points, impl);
    }

    function setCooldownDuration(uint64 newSeconds) external override onlyAdmin {
        cooldownDuration = newSeconds;
        emit CooldownUpdated(newSeconds);
    }

    function setMaxActivePools(uint16 newMax) external override onlyAdmin {
        maxActivePoolsPerOrganizer = newMax;
        emit MaxActivePoolsUpdated(newMax);
    }

    function setCoefficientBounds(uint16 minBps, uint16 maxBps) external override onlyAdmin {
        if (minBps > maxBps) revert BoundsInvalid();
        minCoeffBps = minBps;
        maxCoeffBps = maxBps;
        emit CoefficientBoundsUpdated(minBps, maxBps);
    }

    function setCreatePaused(bool paused) external override onlyAdmin {
        createPaused_ = paused;
        emit CreatePauseUpdated(paused);
    }

    function transferAdmin(address newAdmin) external override onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        address old = admin;
        admin = newAdmin;
        emit AdminTransferred(old, newAdmin);
    }
}
