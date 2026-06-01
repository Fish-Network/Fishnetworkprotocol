# Fish Protocol — Storage Layout Reference

Per-contract slot layout for v1. All `uint256` mappings consume one slot for the mapping pointer; values live at keccak-derived slots.

## `ReputationPoints`

| Slot | Variable | Type | Notes |
|---|---|---|---|
| 0 | `admin` | `address` | Mutable via `setAdmin`. |
| (immutable) | `factory` | `address` | Set in constructor; baked into bytecode. |
| 1 | `rawCapital` | `mapping(address => mapping(uint256 => uint256))` | Raw FP_capital. |
| 2 | `rawParticipation` | `mapping(address => mapping(uint256 => uint256))` | Raw FP_participation. |
| 3 | `sumRawCapital` | `mapping(address => uint256)` | Wallet-level raw sum. |
| 4 | `sumRawParticipation` | `mapping(address => uint256)` | Wallet-level raw sum. |
| 5 | `effectiveTotal` | `mapping(address => uint256)` | Cached DF-scaled total. |
| 6 | `poolDF` | `mapping(uint256 => uint16)` | Per-pool DF in bps. |
| 7 | `poolDFLocked` | `mapping(uint256 => bool)` | One-way latch. |
| 8 | `_minters` | `mapping(address => bool)` | Private. |

`factory` is immutable — stored in code, not storage. Saves a slot read per access.

## `ReputationModule`

| Slot | Variable | Type | Notes |
|---|---|---|---|
| 0 | `admin` | `address` | |
| (immutable) | `factory` | `address` | |
| (immutable) | `reputationPoints` | `IReputationPoints` | |
| 1 | `votingModule` | `address` | Admin-set after VotingModule deploy. |
| 2-4 | `_constants` | `FPConstants` (struct, ~3 slots packed) | uint128 + uint128 fit one slot; the uint16 cluster packs into another. |
| 5 | `authorizedPoolByPoolId` | `mapping(uint256 => address)` | |
| 6 | `deposits` | `mapping(uint256 => mapping(uint256 => Deposit))` | Deposit is uint128 + 2× uint64 = 32 bytes (one slot). |
| 7 | `executed` | `mapping(bytes32 => bool)` | Idempotency latches. |

## `MembershipModule`

| Slot | Variable | Type | Notes |
|---|---|---|---|
| 0 | `admin` | `address` | |
| (immutable) | `factory` | `address` | |
| 1 | `name` | `string` | dynamic |
| 2 | `symbol` | `string` | dynamic |
| 3 | `_nextTokenId` | `uint256` | starts at 1 |
| 4 | `_poolMemberTokenId` | `mapping(uint256 => mapping(address => uint256))` | |
| 5 | `_mintedAt` | `mapping(uint256 => mapping(address => uint64))` | Needed for the "joined before round" check in voting. |
| 6 | `_tokenPool` | `mapping(uint256 => uint256)` | |
| 7 | `_poolBaseURI` | `mapping(uint256 => string)` | |
| 8 | `_ownerOf` | `mapping(uint256 => address)` | |
| 9 | `_balanceOf` | `mapping(address => uint256)` | |
| 10 | `_tokenApprovals` | `mapping(uint256 => address)` | |
| 11 | `_operatorApprovals` | `mapping(address => mapping(address => bool))` | |
| 12 | `isPoolMinter` | `mapping(address => bool)` | |

## `VotingModule`

| Slot | Variable | Type | Notes |
|---|---|---|---|
| 0 | `admin` | `address` | |
| (immutable) | `factory` | `address` | |
| (immutable) | `reputationModule` | `IReputationModule` | |
| 1 | `authorizedPool` | `mapping(uint256 => address)` | |
| 2 | `_pools` | `mapping(uint256 => PoolVoting)` | PoolVoting fits in 1 slot (two uint64 + Outcome enum + bool). |
| 3 | `_votes` | `mapping(uint256 => mapping(address => Vote))` | Vote = Outcome + 2× uint64 = 1 slot. |
| 4 | `_voterList` | `mapping(uint256 => address[])` | Dynamic arrays per pool. |
| 5 | `_inVoterList` | `mapping(uint256 => mapping(address => bool))` | |
| 6 | `_fpClaimed` | `mapping(uint256 => mapping(address => bool))` | |

## `UnredeemablePoolCore` (per clone)

Each clone has its OWN storage but shares the implementation's bytecode. Storage layout below applies to every clone.

| Slot | Variable | Type | Notes |
|---|---|---|---|
| 0 | `_status` (ReentrancyGuard) | `uint256` | |
| 1 | `initialized` | `bool` | one-shot init guard |
| 2 | `poolId` | `uint256` | |
| 3 | `templateVersion` | `uint256` | |
| 4 | `acceptedAsset` | `address` | |
| 5 | `name` | `string` | dynamic |
| 6 | `symbol` | `string` | dynamic |
| 7 | `metadataHash` | `bytes32` | |
| 8 | `openTime` + `closeTime` (packed) | `uint64` + `uint64` | both fit in one slot |
| 9 | `minContribution` + `maxContribution` (packed) | `uint128` + `uint128` | |
| 10 | `poolCap` + `successRule` (packed) | `uint128` + uint8 enum | fits in one slot |
| 11 | `organizer` | `address` | |
| 12 | `factory_` | `address` | |
| 13 | `protocolAdmin` | `address` | |
| 14 | `membershipModule` | `address` | |
| 15 | `votingModule` | `address` | |
| 16 | `reputationModule` | `address` | |
| 17 | `reputationPoints` | `address` | |
| 18 | `reputationCoefficientBps` + lifecycle + prePause (packed) | `uint16` + 2× enum | one slot |
| 19 | `totalAssetsCommitted` | `uint256` | |
| 20 | `poolBalanceAtSettle` | `uint256` | |
| 21 | `totalSupplyAtSettle` | `uint256` | |
| 22 | `settledAt` + `firstDistributePinged` + `winningOutcome` (packed) | uint64 + bool + Outcome | one slot |
| 23 | `decimals` + `_totalSupply` (note: decimals only 1 byte) | uint8 + uint256 | likely separate slots |
| 24 | `_balances` | `mapping(address => uint256)` | |
| 25 | `_userDeposits` | `mapping(address => Deposit[])` | dynamic arrays per user |
| 26 | `_depositors` | `address[]` | enumerable list |
| 27 | `_isDepositor` | `mapping(address => bool)` | |
| 28 | `_distributed` | `mapping(address => bool)` | |
| 29 | `_processedCount` | `uint256` | |

### Clone-specific notes

- **Immutables don't work across clones.** Variables declared `immutable` on the implementation get baked into the implementation's bytecode. Since clones use DELEGATECALL, the immutable value comes from the IMPLEMENTATION's bytecode, not the clone's — which means each clone shares the same immutable value. We deliberately use storage (not `immutable`) for clone-specific values like `factory_` and `organizer`.
- **Storage gaps:** v1 does not reserve `__gap` slots. The implementation is intentionally not upgradeable per-clone. A new implementation deployment is a new code path for new pools.

## `UnredeemablePoolFactory`

| Slot | Variable | Type | Notes |
|---|---|---|---|
| 0 | `admin` | `address` | |
| 1 | `membershipModule` | `address` | |
| 2 | `votingModule` | `address` | |
| 3 | `reputationModule` | `address` | |
| 4 | `reputationPoints` | `address` | |
| 5 | `poolImplementation` | `address` | |
| 6 | `cooldownDuration` + `maxActivePoolsPerOrganizer` + `minCoeffBps` + `maxCoeffBps` + `createPaused_` (packed) | uint64 + 3× uint16 + bool | 15 bytes — packs into one slot |
| 7 | `nextPoolId` | `uint256` | |
| 8 | `poolById` | `mapping(uint256 => address)` | |
| 9 | `poolIdByAddress` | `mapping(address => uint256)` | |
| 10 | `activePoolCount` | `mapping(address => uint16)` | |
| 11 | `lastOpenedAt` | `mapping(address => uint64)` | |
| 12 | `allPools` | `address[]` | enumerable list |

## Packing reasoning summary

- `uint16` fields cluster together where possible (Pool config and Factory tunables).
- Timestamps use `uint64` — enough for the year 292,277,026,596.
- `Deposit` and `Vote` structs are deliberately 32-byte-aligned to fit in one slot.
- `FPConstants` packs into ~3 slots; the uint128 fields each take half a slot, the uint16/uint32 cluster fills another.

## Upgrade considerations

- **No proxies.** v1 deploys regular contracts and EIP-1167 minimal clones. There's no Transparent / UUPS / Beacon pattern.
- **Implementation replacement.** `Factory.setModules(... newImpl)` changes only what FUTURE clones point to. Existing clones keep their original code path forever.
- **If a bug is found** in the implementation, the only remedy is: deploy a fixed implementation, point the Factory at it, and migrate users/pools off the buggy implementation organically (no on-chain forced migration).
- **v2 candidates** for upgradeability: Beacon proxy if per-clone upgrade flexibility is wanted, with `__gap` slots reserved on each storage cluster.
