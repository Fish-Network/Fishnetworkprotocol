// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IContributionModule} from "./interfaces/IContributionModule.sol";
import {IMembershipModule} from "./interfaces/IMembershipModule.sol";
import {IReputationModule} from "./interfaces/IReputationModule.sol";
import {IUnredeemablePoolCore} from "./interfaces/IUnredeemablePoolCore.sol";
import {MinimalClones} from "./libraries/MinimalClones.sol";
import {ReputationConfig, UnredeemableModuleSet, UnredeemablePoolConfig} from "./types/UnredeemablePoolTypes.sol";

contract UnredeemablePoolFactory {
    enum ModuleType {
        Membership,
        Contribution,
        Reputation
    }

    error Unauthorized();
    error ZeroAddress();
    error InvalidConfig();
    error InvalidTimeRange();
    error InvalidContributionBounds();
    error InvalidPoolCap();
    error UnapprovedModule(ModuleType moduleType, address module);
    error InvalidReputationConfig();

    event ProtocolAdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    event PoolImplementationUpdated(address indexed previousImplementation, address indexed newImplementation);
    event ModuleApprovalSet(ModuleType indexed moduleType, address indexed module, bool approved);
    event UnredeemablePoolCreated(
        address indexed pool,
        uint256 indexed poolId,
        uint256 indexed templateId,
        uint256 templateVersion,
        address creator,
        address organizer,
        address poolOperator,
        address protocolAdmin,
        address acceptedAsset,
        bytes32 metadataHash
    );
    event ModulesAttached(
        address indexed pool,
        address indexed membershipModule,
        address indexed contributionModule,
        address reputationModule
    );
    event ConfigReference(address indexed pool, bytes32 metadataHash, bytes32 reputationConfigHash);

    address public protocolAdmin;
    address public poolImplementation;

    mapping(address => bool) public approvedMembershipModules;
    mapping(address => bool) public approvedContributionModules;
    mapping(address => bool) public approvedReputationModules;

    modifier onlyProtocolAdmin() {
        if (msg.sender != protocolAdmin) revert Unauthorized();
        _;
    }

    constructor(address initialProtocolAdmin, address initialPoolImplementation) {
        if (initialProtocolAdmin == address(0) || initialPoolImplementation == address(0)) revert ZeroAddress();
        protocolAdmin = initialProtocolAdmin;
        poolImplementation = initialPoolImplementation;
    }

    function setProtocolAdmin(address newProtocolAdmin) external onlyProtocolAdmin {
        if (newProtocolAdmin == address(0)) revert ZeroAddress();
        emit ProtocolAdminUpdated(protocolAdmin, newProtocolAdmin);
        protocolAdmin = newProtocolAdmin;
    }

    function setPoolImplementation(address newPoolImplementation) external onlyProtocolAdmin {
        if (newPoolImplementation == address(0)) revert ZeroAddress();
        emit PoolImplementationUpdated(poolImplementation, newPoolImplementation);
        poolImplementation = newPoolImplementation;
    }

    function setModuleApproval(ModuleType moduleType, address module, bool approved) external onlyProtocolAdmin {
        if (module == address(0)) revert ZeroAddress();

        if (moduleType == ModuleType.Membership) {
            approvedMembershipModules[module] = approved;
        } else if (moduleType == ModuleType.Contribution) {
            approvedContributionModules[module] = approved;
        } else {
            approvedReputationModules[module] = approved;
        }

        emit ModuleApprovalSet(moduleType, module, approved);
    }

    function createUnredeemablePool(
        UnredeemablePoolConfig calldata config,
        ReputationConfig calldata reputationConfig,
        UnredeemableModuleSet calldata modules
    ) external returns (address pool) {
        _validateConfig(config);
        _validateModules(modules);
        _validateReputationConfig(reputationConfig);

        // Explicitly touch required module interfaces as a safety check that they are contracts.
        IMembershipModule(modules.membershipModule).moduleId();
        IContributionModule(modules.contributionModule).moduleId();
        IReputationModule(modules.reputationModule).moduleId();

        pool = MinimalClones.clone(poolImplementation);
        IUnredeemablePoolCore(pool).initialize(config, reputationConfig, modules, address(this));

        emit UnredeemablePoolCreated(
            pool,
            config.poolId,
            config.templateId,
            config.templateVersion,
            config.creator,
            config.organizer,
            config.poolOperator,
            config.protocolAdmin,
            config.acceptedAsset,
            config.metadataHash
        );
        emit ModulesAttached(pool, modules.membershipModule, modules.contributionModule, modules.reputationModule);
        emit ConfigReference(pool, config.metadataHash, keccak256(abi.encode(reputationConfig)));
    }

    function _validateConfig(UnredeemablePoolConfig calldata config) internal view {
        if (
            config.creator == address(0) || config.organizer == address(0) || config.poolOperator == address(0)
                || config.protocolAdmin == address(0)
        ) revert InvalidConfig();
        if (config.protocolAdmin != protocolAdmin) revert InvalidConfig();
        if (config.acceptedAsset == address(0)) revert InvalidConfig();
        if (config.openTime >= config.closeTime || config.closeTime <= block.timestamp) revert InvalidTimeRange();
        if (config.minContribution > config.maxContribution) revert InvalidContributionBounds();
        if (config.poolCap == 0) revert InvalidPoolCap();
    }

    function _validateModules(UnredeemableModuleSet calldata modules) internal view {
        if (modules.membershipModule == address(0) || modules.contributionModule == address(0) || modules.reputationModule == address(0)) {
            revert ZeroAddress();
        }
        if (!approvedMembershipModules[modules.membershipModule]) {
            revert UnapprovedModule(ModuleType.Membership, modules.membershipModule);
        }
        if (!approvedContributionModules[modules.contributionModule]) {
            revert UnapprovedModule(ModuleType.Contribution, modules.contributionModule);
        }
        if (!approvedReputationModules[modules.reputationModule]) {
            revert UnapprovedModule(ModuleType.Reputation, modules.reputationModule);
        }
    }

    function _validateReputationConfig(ReputationConfig calldata reputationConfig) internal pure {
        uint256 tierCount = reputationConfig.tierThresholds.length;
        if (reputationConfig.maxTiers == 0 || tierCount == 0 || tierCount != reputationConfig.maxTiers) {
            revert InvalidReputationConfig();
        }
        if (tierCount != reputationConfig.tierMultipliersBps.length) revert InvalidReputationConfig();

        uint256 lastThreshold;
        for (uint256 i = 0; i < tierCount; ++i) {
            uint256 threshold = reputationConfig.tierThresholds[i];
            if (i > 0 && threshold <= lastThreshold) revert InvalidReputationConfig();
            uint256 multiplierBps = reputationConfig.tierMultipliersBps[i];
            if (multiplierBps == 0 || multiplierBps > 10_000) revert InvalidReputationConfig();
            lastThreshold = threshold;
        }
    }
}

/*
PHASE 2 DEFERRED
- deposit logic
- unit accounting
- detailed event schema
- metadata expansion
- final contribution flow
*/