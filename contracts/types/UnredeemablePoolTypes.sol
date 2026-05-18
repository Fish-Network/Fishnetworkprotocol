/// @notice Success outcomes for a pool lifecycle.
enum SuccessRule {
    TargetReached,
    ManualSuccessfulClose,
    CustomRule
}

/// @notice Flat config for creating a new unredeemable pool.
struct UnredeemablePoolConfig {
    uint256 templateId;
    uint256 poolId;
    uint256 templateVersion;
    address creator;
    address organizer;
    address poolOperator;
    address protocolAdmin;
    address acceptedAsset;
    uint64 openTime;
    uint64 closeTime;
    uint128 minContribution;
    uint128 maxContribution;
    uint128 poolCap;
    bytes32 metadataHash;
    SuccessRule successRule;
}

/// @notice Module addresses required for unredeemable pool creation.
struct UnredeemableModuleSet {
    address membershipModule;
    address contributionModule;
    address reputationModule;
}

/// @notice Reputation configuration passed at pool creation.
struct ReputationConfig {
    uint8 maxTiers;
    uint128 minJoinPoints;
    uint128 contributionPointsPerAsset;
    uint128 organizerBonusPoints;
    uint128 operatorBonusPoints;
    uint256[] tierThresholds;
    uint256[] tierMultipliersBps;
}