// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IReputationPoints} from "../interfaces/IReputationPoints.sol";
import {FPCategory} from "../types/Reputation.sol";

/// @notice Canonical, wallet-bound, non-transferable FP ledger.
/// @dev Stores RAW per-pool per-category; caches DF-scaled effective total.
contract ReputationPoints is IReputationPoints {
    error NotAdmin();
    error NotFactory();
    error NotMinter();
    error ZeroAddress();
    error ZeroAmount();
    error PoolDFAlreadyLocked(uint256 poolId);
    error PoolDFNotLocked(uint256 poolId);
    error DFBoundsViolated(uint16 dfBps);

    address public override admin;
    address public immutable override factory;

    mapping(address => mapping(uint256 => uint256)) public rawCapital;
    mapping(address => mapping(uint256 => uint256)) public rawParticipation;
    mapping(address => uint256) public sumRawCapital;
    mapping(address => uint256) public sumRawParticipation;
    mapping(address => uint256) public effectiveTotal;

    mapping(uint256 => uint16) public override poolDF;
    mapping(uint256 => bool)   public override poolDFLocked;

    mapping(address => bool) private _minters;

    modifier onlyAdmin()   { if (msg.sender != admin)   revert NotAdmin();   _; }
    modifier onlyFactory() { if (msg.sender != factory) revert NotFactory(); _; }
    modifier onlyMinter()  { if (!_minters[msg.sender]) revert NotMinter();  _; }

    constructor(address initialAdmin, address factory_) {
        if (initialAdmin == address(0) || factory_ == address(0)) revert ZeroAddress();
        admin   = initialAdmin;
        factory = factory_;
        emit AdminUpdated(address(0), initialAdmin);
    }

    function mint(address user, uint256 poolId, uint256 rawAmount, FPCategory category)
        external override onlyMinter
    {
        if (user == address(0)) revert ZeroAddress();
        if (rawAmount == 0)     revert ZeroAmount();
        if (!poolDFLocked[poolId]) revert PoolDFNotLocked(poolId);

        if (category == FPCategory.Capital) {
            rawCapital[user][poolId] += rawAmount;
            sumRawCapital[user]      += rawAmount;
        } else {
            rawParticipation[user][poolId] += rawAmount;
            sumRawParticipation[user]      += rawAmount;
        }

        uint256 effDelta = (rawAmount * uint256(poolDF[poolId])) / 10_000;
        effectiveTotal[user] += effDelta;

        emit PointsMinted(user, poolId, rawAmount, category, effDelta, effectiveTotal[user]);
    }

    function lockPoolDF(uint256 poolId, uint16 dfBps) external override onlyMinter {
        if (poolDFLocked[poolId]) revert PoolDFAlreadyLocked(poolId);
        // Bounds enforced upstream by Factory; safety floor here.
        if (dfBps == 0) revert DFBoundsViolated(dfBps);
        poolDF[poolId] = dfBps;
        poolDFLocked[poolId] = true;
        emit PoolDFLocked(poolId, dfBps);
    }

    // Views
    function getCapitalPoints(address user) external view override returns (uint256) { return sumRawCapital[user]; }
    function getParticipationPoints(address user) external view override returns (uint256) { return sumRawParticipation[user]; }
    function getPoolCapital(address user, uint256 poolId) external view override returns (uint256) { return rawCapital[user][poolId]; }
    function getPoolParticipation(address user, uint256 poolId) external view override returns (uint256) { return rawParticipation[user][poolId]; }
    function getTotalPoints(address user) external view override returns (uint256) { return effectiveTotal[user]; }
    function getPoolTotal(address user, uint256 poolId) external view override returns (uint256) {
        return ((rawCapital[user][poolId] + rawParticipation[user][poolId]) * uint256(poolDF[poolId])) / 10_000;
    }

    // Admin
    function setMinter(address minter, bool authorized) external override onlyAdmin {
        if (minter == address(0)) revert ZeroAddress();
        _minters[minter] = authorized;
        emit MinterAuthorizationUpdated(minter, authorized);
    }

    function setAdmin(address newAdmin) external override onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        address old = admin;
        admin = newAdmin;
        emit AdminUpdated(old, newAdmin);
    }

    function isMinter(address minter) external view override returns (bool) { return _minters[minter]; }
}
