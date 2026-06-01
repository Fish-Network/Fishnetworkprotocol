# Fish Points — Developer Guide


## Overview

Fish Points is a **non-transferable, event-driven reputation system** for Fish Pools.

It is designed to be:

* simple to integrate
* deterministic
* auditable
* wallet-native

This guide explains how to build on top of the system without needing to understand internal implementation details.

---

## Core Model

All integrations should rely on this invariant:

```text
FP_total = FP_capital + FP_participation
```

### FP(capital)

Reputation from capital commitment over time.

### FP(participation)

Reputation from:

* voting behavior
* organizer outcomes

---

## Discount Factor (DF)

DF is a per-pool multiplier applied to all FP issued in that pool.

- Set at pool creation (within `[minCoeffBps, maxCoeffBps]` bounds).
- Mutable in `Draft`; locked at `Draft → Open` transition.
- Applied at READ time via the cached `effectiveTotal` field; raw FP is stored unscaled.

## New ReputationPoints API

```text
getCapitalPoints(user)         → raw FP_capital sum across all pools
getParticipationPoints(user)   → raw FP_participation sum across all pools
getTotalPoints(user)           → cached effective total (Σ raw × DF per pool)
getPoolCapital(user, poolId)   → raw capital in one pool
getPoolParticipation(user, p)  → raw participation in one pool
getPoolTotal(user, poolId)     → (raw cap + raw part) × DF for one pool
poolDF(poolId)                 → DF for the pool, 0 if not yet locked
poolDFLocked(poolId)           → whether DF is finalized
```

**Invariant per pool:** `getPoolTotal == (getPoolCapital + getPoolParticipation) × DF / 10_000`.

**Invariant across pools:** `getTotalPoints == Σ over pools p of (rawCap(u,p) + rawPart(u,p)) × DF(p) / 10_000`. Collapses to `(getCap + getPart) × DF` only when every participated pool has the same DF.

---

## Key Principles

When building on top of Fish Points:

* treat scores as **event-driven**
* rely on **finalized values only**
* assume **idempotency for all score events**
* do not infer reputation from raw actions alone
* always prefer **explicit FP events**

---

## Core Entities

### Wallet

Represents a user.

Fields:

* `wallet_address`
* `verified`

---

### Pool

Represents a coordination unit.

Fields:

* `pool_id`
* `organizer_wallet`
* `state`
* `start_time`
* `end_time`
* `winning_proposal_id`

---

### Membership

Tracks when a wallet joins a Pool.

Fields:

* `pool_id`
* `wallet_address`
* `joined_at`

---

### Vote

Represents a vote in a Pool.

Fields:

* `vote_id`
* `pool_id`
* `wallet_address`
* `proposal_id`
* `cast_at`
* `is_valid`
* `is_final`

---

### Deposit

Represents capital committed to a Pool.

Fields:

* `deposit_id`
* `pool_id`
* `wallet_address`
* `amount_usdc`
* `deposited_at`
* `withdrawn_at`

---

### FP Event

Represents a change in reputation.

Fields:

* `fp_event_id`
* `idempotency_key`
* `wallet_address`
* `pool_id`
* `event_type`
* `fp_capital_delta`
* `fp_participation_delta`
* `fp_total_delta`
* `occurred_at`

---

## Pool Lifecycle

```text
draft → open → active → closed → settled → distributed
```

### Important States

* `open` → pool becomes valid
* `settled` → pool successfully completes
* `distributed` → first investor outcome delivered

Most scoring logic depends on these transitions.

---

## Score-Creating Events

These are the only events that should be treated as canonical reputation updates.

### Organizer Events

* `pool_opened`
* `pool_settled`
* `distribution_batch_completed`

### Participation Events

* `vote_finalized`

### Capital Events

* `capital_withdrawn`
* `capital_settled`

---

## Organizer Scoring

| Event              | Points |
| ------------------ | ------ |
| Pool opened        | +1     |
| Pool settled       | +5     |
| First distribution | +25    |

### Notes

* Distribution reward is **one-time only**
* Pools must reach `settled` before distribution counts

---

## Participation Scoring

### Formula

```text
FP_vote = (1 + AccuracyBonus) × TimingMultiplier
```

### Constants

* Base = 1
* Accuracy Bonus = 2

---

### Timing Buckets

| Range   | Multiplier |
| ------- | ---------- |
| 0–33%   | 1.5        |
| 33–80%  | 1.0        |
| 80–100% | 0.75       |

---

### Accuracy Rules

Accuracy bonus applies only if:

* Pool reaches `settled`
* vote matches winning proposal
* vote is before 80% of round duration

---

### Important

* only **final vote** counts
* intermediate vote updates should be ignored
* invalid votes produce **0 FP**

---

## Capital Scoring

### Formula

```text
FP_capital = Deposit × (days_held / 30)
```

---

### Rules

* accrues over time

* stops at:

  * withdrawal
  * OR settlement

* finalized only on:

  * withdrawal
  * settlement

---

### Developer Notes

* do not treat live capital accrual as final
* UI may show estimates, but backend should rely on finalized events

---

## Eligibility Rules

A vote only earns FP if:

* wallet is verified
* user joined before vote opened
* vote is valid
* vote is final
* vote is within round window

If any condition fails:

```text
FP = 0
```

---

## Idempotency

All FP events must be treated as idempotent.

### Example Keys

```text
keccak256("FP:capital:fin", poolId, depositId)
keccak256("FP:vote",        poolId, user)
keccak256("FP:org",         poolId, uint8(milestone))
```

### Integration Rule

Always deduplicate by:

* `idempotency_key`

---

## Recommended API Endpoints

### Wallet Score

```
GET /api/fp/wallets/{wallet}
```

Returns:

* fp_capital_total
* fp_participation_total
* fp_total

---

### Wallet Events

```
GET /api/fp/wallets/{wallet}/events
```

Returns:

* full event history

---

### Pool Summary

```
GET /api/fp/pools/{pool_id}
```

Returns:

* state
* organizer
* scoring milestones

---

### Organizer Summary

```
GET /api/fp/organizers/{wallet}
```

Returns:

* pools opened
* pools settled
* pools distributed
* participation score

---

## Webhooks (Optional)

Recommended topics:

* `pool.opened`
* `pool.settled`
* `pool.distributed`
* `vote.finalized`
* `capital.withdrawn`
* `capital.settled`
* `fp.event.created`

---

## Common Use Cases

### Build With Fish Points

* wallet reputation dashboards
* organizer leaderboards
* Pool discovery tools
* governance analytics
* scoring explorers
* trust systems

---

## What NOT to Assume

Do not assume:

* Fish Points are transferable
* Fish Points are redeemable
* every vote earns bonus
* every distribution adds new score
* vote submission = final vote
* live capital = finalized score

---

## Stability Guarantees

You can rely on:

* FP_total = FP_capital + FP_participation
* milestone-based organizer rewards
* final vote scoring only
* settlement-gated accuracy
* capital finalized at withdrawal/settlement
* `poolDF` is immutable once locked.
* `getTotalPoints` is computed by accumulator, not iteration — gas-safe for arbitrarily many pools per wallet.

---

## Minimal Integration

To build quickly, index:

### Objects

* wallets
* pools
* votes
* deposits
* fp_events

### Events

* pool_opened
* pool_settled
* distribution_batch_completed
* vote_finalized
* capital_withdrawn
* capital_settled

---

## Example Score Flow

1. Organizer opens Pool → +1
2. Organizer settles Pool → +5
3. Deposit 1000 for 30 days → +1000
4. Early correct vote → +4.5

Final:

```text
FP_capital = 1000
FP_participation = 10.5
FP_total = 1010.5
```

---

## Final Note

Fish Points is a **reputation system, not a rewards system**.

Build integrations that:

* surface signal
* improve trust
* clarify contribution

Avoid treating it like:

* a token
* a points marketplace
* a gamified reward loop

---

## Questions / Contributions

If you're building something interesting on top of Fish Points, open a PR or issue — contributions are welcome.
