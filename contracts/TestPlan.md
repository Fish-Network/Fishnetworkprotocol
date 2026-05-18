# Fish Protocol — Manual Test Plan

This document defines manual verification scenarios for the v1 contracts. Because the repo has no in-repo toolchain, all scenarios are run externally — in Remix or a local fork into Foundry/Hardhat.

## 0. Environment setup

1. Clone this repo into a Foundry project (or paste each `.sol` file into a Remix workspace at the same path).
2. Deploy in this order. Each subsequent module needs the previous addresses:
   1. `UnredeemablePoolFactory(admin)` — only takes admin. Record address as `FACTORY`.
   2. `ReputationPoints(admin, FACTORY)`. Record as `POINTS`.
   3. `ReputationModule(admin, FACTORY, POINTS)`. Record as `REP`.
   4. `MembershipModule("Fish Membership", "FISHM", admin, FACTORY)`. Record as `MEMBERSHIP`.
   5. `VotingModule(admin, FACTORY, REP)`. Record as `VOTING`.
   6. `UnredeemablePoolCore()` (no args; never initialized directly — it's the clone template). Record as `IMPL`.
3. Wire-up calls (all by admin):
   1. `Factory.setModules(MEMBERSHIP, VOTING, REP, POINTS, IMPL)`.
   2. `ReputationModule.setVotingModule(VOTING)`.
   3. `ReputationPoints.setMinter(REP, true)`.
4. Verify wiring:
   - `Factory.poolImplementation()` returns `IMPL`.
   - `ReputationModule.votingModule()` returns `VOTING`.
   - `ReputationPoints.isMinter(REP)` returns `true`.

`createPool` reverts with `ZeroAddress` until `Factory.setModules` has been called. This is intentional — it prevents accidentally deploying a pool with a missing implementation.

## 1. Smoke tests (per contract)

| Contract | Check |
|---|---|
| All | Each contract has `admin == deployer` after constructor. |
| All | `factory` view returns the Factory address (where applicable). |
| ReputationPoints | `mint` reverts with `PoolDFNotLocked` if called before `lockPoolDF`. |
| ReputationModule | `getConstants()` returns the defaults from spec Section 7. |
| MembershipModule | `mintMembership` reverts with `NotAuthorized` if caller is not admin or in `isPoolMinter`. |
| VotingModule | `castVote` reverts with `RoundNotOpen` before `openRound`. |
| Factory | `createPool` reverts with `CreatePaused` after `setCreatePaused(true)`. |

## 2. Lifecycle happy path

Setup a pool with `minContribution = 100`, `poolCap = 1000`, `successRule = MinContributionReached`, DF = 1.0× (10000 bps).

1. `createPool` from EOA `O` → pool clone deployed at address `P`.
2. `P.openContributions()` from `O` → state Open; organizer FP `O` shows `+1e18` participation in `poolId`.
3. Two depositors `A` (300) and `B` (400) call `deposit`. Capital recorded. `totalAssetsCommitted = 700`.
4. `P.activatePool()` from `O` → state Active; voting round opens.
5. `A.castVote(Yes)`, `B.castVote(No)` → recorded.
6. `P.closePool()` from `O` → state Closed (success since 700 ≥ 100).
7. `P.settle(Yes)` from `O` → state Settled; +5 FP fires; `winningOutcome = Yes`.
8. `A.claimVoteFP(poolId)` (via VotingModule) → `A` gets `(1+2) × earlyMult = 4.5e18` FP (assuming early).
9. `B.claimVoteFP(poolId)` → `B` gets `1 × earlyMult = 1.5e18` (wrong vote, no bonus).
10. `A.claimCapitalFP(0)` → A's capital FP minted using `daysHeld = (settledAt - depositedAt)/1 days`.
11. `P.distribute(0, 2)` → 300 USDC back to A, 400 USDC back to B; +25 FP fires once.
12. State → Distributed; Factory's `activePoolCount[O]` decremented to 0.

Verify all FP totals match expected formulas with DF = 1.0×.

## 3. Failed pool path

1. Create pool with `minContribution = 1000`.
2. `openContributions` → +1 FP to organizer.
3. Single deposit of 200 from `A`.
4. `closePool` → state Failed (200 < 1000).
5. `A.refund(0)` → 200 back; capital FP minted with `daysHeld = refundTime - depositTime`.
6. `A.claimVoteFP` succeeds only if A voted; produces `base × timing` (no accuracy, since `winning == None`).

## 4. Force-close from Open

1. Create pool with `closeTime = now + 1 hour`.
2. `openContributions` → state Open.
3. Wait 1 hour (or `vm.warp` if Foundry).
4. Any address calls `closePool` → routes to Failed (no deposits, threshold unmet). VotingModule.closeRound is skipped because the round was never opened.

## 5. Pause / unpause

For each non-terminal state (Draft, Open, Active, Closed, Settled):

1. Enter state.
2. `pause()` → state Paused.
3. Any state-restricted action (deposit, vote, etc.) reverts.
4. `unpause()` → state restored to pre-pause.

Confirm `_prePauseState` is correctly preserved through nested-looking calls (only one pause-depth allowed in v1).

## 6. Anti-gaming (Factory)

1. `O` opens pool 1, 2, 3 within `maxActivePoolsPerOrganizer` (3). All succeed.
2. `O` tries to open pool 4 (without finishing 1–3) → reverts with `MaxActiveReached`.
3. `O` settles + distributes pool 1 → `activePoolCount[O] = 2`.
4. `O` immediately tries to open pool 4 → reverts with `CooldownActive` (14 days haven't passed).
5. `vm.warp(14 days)` then open pool 4 → succeeds.

## 7. DF behavior

Run the lifecycle happy path three times with DF = 5000 (0.5×), 10000 (1.0×), 20000 (2.0×).

- Verify `getPoolCapital` and `getPoolParticipation` return the SAME raw values across all three runs.
- Verify `getPoolTotal` and `getTotalPoints` scale linearly with DF.
- Verify `lockPoolDF` is idempotent-blocked (a second call reverts with `PoolDFAlreadyLocked`).
- Try `setReputationCoefficient` after pool transitions to Open → reverts with `WrongState`.

## 8. Idempotency

For each idempotency-keyed call (`finalizeCapital`, `mintVoteFP`, `mintOrganizerMilestone`):

1. Trigger the natural flow → mint happens.
2. Trigger the same flow again (e.g., via direct re-call from the authorized caller) → emits `IdempotentReplayIgnored` with the matching key; no double-mint.

## 9. Capital math

1. `A` deposits 1000 at t0; withdraws at t0 + 15 days → expected FP_capital_raw = `1000 × 15 / 30 = 500`.
2. `A` deposits 500 at t0 and another 500 at t0+10 days; settles at t0+30 days → expected FP_capital_raw = `500 × 30/30 + 500 × 20/30 ≈ 833.33`.

## 10. Voting math (from PointsExamples.md)

Run the four canonical scenarios:
- Early correct → `4.5e18`
- Late correct  → `0.75e18`
- Early wrong   → `1.5e18`
- Pool failed, early correct → `1.5e18` (no accuracy)

## 11. Invariants

After each scenario above, run the spot-checks from spec Section 13:

- `Σ deposits − Σ withdrawn − Σ refunded − Σ distributed == acceptedAsset.balanceOf(pool)`
- `getCapitalPoints + getParticipationPoints` ≠ `getTotalPoints` in general (only equal when DF = 1.0× on every pool the user touched).
- `getPoolTotal(u, p) == (getPoolCapital + getPoolParticipation) × poolDF / 10_000` exactly.

## 12. Negative tests

For each privileged function in the permission matrix (spec Section 9):

1. Call from an unauthorized address → expect the specific revert error (e.g., `NotOrganizer`, `NotFactory`, `NotMinter`).
2. Call in a wrong state → expect `WrongState(expected, actual)`.

## 13. Sign-off

A reviewer signs off when:
- All 12 sections above pass on a clean deployment.
- No state lookups return unexpected zero values.
- All emitted events match the schema in the interface files.
