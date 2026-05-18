// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IUnredeemablePoolCore} from "./interfaces/IUnredeemablePoolCore.sol";
import {IUnredeemablePoolFactory} from "./interfaces/IUnredeemablePoolFactory.sol";
import {IMembershipModule} from "./interfaces/IMembershipModule.sol";
import {IVotingModule} from "./interfaces/IVotingModule.sol";
import {IReputationModule} from "./interfaces/IReputationModule.sol";
import {IReputationPoints} from "./interfaces/IReputationPoints.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC20Metadata} from "./interfaces/IERC20Metadata.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {ReentrancyGuard} from "./libraries/ReentrancyGuard.sol";
import {UnredeemablePoolConfig, UnredeemableModuleSet} from "./types/PoolConfig.sol";
import {LifecycleState, SuccessRule} from "./types/PoolLifecycle.sol";
import {Outcome} from "./types/Voting.sol";
import {Deposit} from "./types/Deposit.sol";
import {OrganizerMilestone} from "./types/Reputation.sol";

contract UnredeemablePoolCore is IUnredeemablePoolCore, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error AlreadyInitialized();
    error ZeroAddress();
    error InvalidConfig();
    error NotOrganizer();
    error NotOrganizerOrAdmin();
    error NotMember();
    error WrongState(LifecycleState expected, LifecycleState actual);
    error PausedOrTerminal();
    error CapExceeded();
    error MinContribution();
    error MaxContribution();
    error DepositNotFound(uint256 depositId);
    error DepositAlreadyFinalized(uint256 depositId);
    error NotDepositor();
    error CooldownNotElapsed();
    error InvalidDFBps();
    error DistributionOOB();
    error DistributionAlreadyComplete();
    error NotTransferable();

    // ===== Immutable / one-shot init =====

    bool   public initialized;
    uint256 public override poolId;
    uint256 public templateVersion;
    address public acceptedAsset;
    string  public name;
    string  public symbol;
    bytes32 public metadataHash;

    uint64  public openTime;
    uint64  public closeTime;
    uint128 public minContribution;
    uint128 public maxContribution;
    uint128 public poolCap;
    SuccessRule public successRule;

    address public override organizer;
    address public factory_;
    address public protocolAdmin;

    address public membershipModule;
    address public votingModule;
    address public reputationModule;
    address public reputationPoints;

    uint16 public override reputationCoefficientBps;

    LifecycleState public override lifecycleState;
    LifecycleState private _prePauseState;

    // ===== Capital state =====

    uint256 public override totalAssetsCommitted;
    uint256 public poolBalanceAtSettle;
    uint256 public totalSupplyAtSettle;
    uint64  public settledAt;
    bool    public firstDistributePinged;
    Outcome public winningOutcome;

    // LP unit accounting (non-transferable)
    uint8   public decimals;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    // Deposits per user
    mapping(address => Deposit[]) internal _userDeposits;

    // Depositor enumeration for distribution
    address[] internal _depositors;
    mapping(address => bool) internal _isDepositor;
    mapping(address => uint256) internal _unitsAtSettle;
    mapping(address => bool) internal _distributed;
    uint256 internal _processedCount;

    // ===== Modifiers =====

    modifier onlyOrganizer() {
        if (msg.sender != organizer) revert NotOrganizer();
        _;
    }

    modifier onlyOrganizerOrAdmin() {
        if (msg.sender != organizer && msg.sender != protocolAdmin) revert NotOrganizerOrAdmin();
        _;
    }

    modifier inState(LifecycleState expected) {
        if (lifecycleState != expected) revert WrongState(expected, lifecycleState);
        _;
    }

    function initialize(
        uint256 poolId_,
        UnredeemablePoolConfig calldata config,
        UnredeemableModuleSet calldata modules,
        address organizer_,
        uint16  dfBps,
        address factoryAddress
    ) external override {
        if (initialized) revert AlreadyInitialized();
        if (config.acceptedAsset == address(0)
            || modules.membershipModule == address(0)
            || modules.votingModule == address(0)
            || modules.reputationModule == address(0)
            || modules.reputationPoints == address(0)
            || organizer_ == address(0)
            || factoryAddress == address(0)) revert ZeroAddress();
        if (bytes(config.name).length == 0)  revert InvalidConfig();
        if (config.poolCap == 0)             revert InvalidConfig();

        initialized      = true;
        poolId           = poolId_;
        templateVersion  = config.templateVersion;
        acceptedAsset    = config.acceptedAsset;
        name             = config.name;
        symbol           = "FISH-U";
        metadataHash     = config.metadataHash;
        openTime         = config.openTime;
        closeTime        = config.closeTime;
        minContribution  = config.minContribution;
        maxContribution  = config.maxContribution;
        poolCap          = config.poolCap;
        successRule      = config.successRule;

        organizer        = organizer_;
        factory_         = factoryAddress;
        protocolAdmin    = IUnredeemablePoolFactory(factoryAddress).admin();

        membershipModule = modules.membershipModule;
        votingModule     = modules.votingModule;
        reputationModule = modules.reputationModule;
        reputationPoints = modules.reputationPoints;

        reputationCoefficientBps = dfBps;
        lifecycleState   = LifecycleState.Draft;

        decimals = IERC20Metadata(config.acceptedAsset).decimals();

        emit PoolInitialized(poolId_, address(this), config.acceptedAsset, dfBps);
    }

    // ===== Pause (orthogonal) =====

    function pause() external override onlyOrganizerOrAdmin {
        if (lifecycleState == LifecycleState.Paused
         || lifecycleState == LifecycleState.Distributed
         || lifecycleState == LifecycleState.Failed) revert PausedOrTerminal();
        _prePauseState = lifecycleState;
        LifecycleState prev = lifecycleState;
        lifecycleState = LifecycleState.Paused;
        emit PoolStateTransitioned(poolId, prev, LifecycleState.Paused);
        emit PoolPaused(poolId, prev);
    }

    function unpause() external override onlyOrganizerOrAdmin inState(LifecycleState.Paused) {
        LifecycleState restored = _prePauseState;
        lifecycleState = restored;
        emit PoolStateTransitioned(poolId, LifecycleState.Paused, restored);
        emit PoolUnpaused(poolId, restored);
    }

    // ===== DF (mutable in Draft only) =====

    function setReputationCoefficient(uint16 newBps)
        external override onlyOrganizer inState(LifecycleState.Draft)
    {
        uint16 minBps = IUnredeemablePoolFactory(factory_).minCoeffBps();
        uint16 maxBps = IUnredeemablePoolFactory(factory_).maxCoeffBps();
        if (newBps < minBps || newBps > maxBps) revert InvalidDFBps();
        uint16 old = reputationCoefficientBps;
        reputationCoefficientBps = newBps;
        emit ReputationCoefficientUpdated(poolId, old, newBps);
    }

    // ===== LP unit views (non-transferable) =====

    function totalSupply() external view returns (uint256) { return _totalSupply; }
    function balanceOf(address a) external view returns (uint256) { return _balances[a]; }
    function transfer(address, uint256) external pure returns (bool) { revert NotTransferable(); }
    function transferFrom(address, address, uint256) external pure returns (bool) { revert NotTransferable(); }
    function approve(address, uint256) external pure returns (bool) { revert NotTransferable(); }
    function allowance(address, address) external pure returns (uint256) { return 0; }

    function getDepositCount(address user) external view override returns (uint256) {
        return _userDeposits[user].length;
    }

    function _transitionTo(LifecycleState next) internal {
        LifecycleState prev = lifecycleState;
        lifecycleState = next;
        emit PoolStateTransitioned(poolId, prev, next);
    }
}
