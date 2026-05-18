// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {SuccessRule} from "./PoolLifecycle.sol";

/// @notice Flat config passed by the Factory at pool creation. Pool snapshots all fields at init.
struct UnredeemablePoolConfig {
    uint256 templateVersion;
    address acceptedAsset;        // ERC20 stablecoin etc.
    string  name;
    bytes32 metadataHash;         // off-chain metadata pointer (IPFS, etc.)
    uint64  openTime;             // earliest time openContributions() may be called
    uint64  closeTime;            // earliest time anyone-can-close kicks in
    uint128 minContribution;
    uint128 maxContribution;      // 0 = unbounded per-tx
    uint128 poolCap;              // hard cap on totalAssetsCommitted; required > 0
    SuccessRule successRule;
}

/// @notice Singleton module addresses bound to a pool at init.
struct UnredeemableModuleSet {
    address membershipModule;
    address votingModule;
    address reputationModule;
    address reputationPoints;
}
