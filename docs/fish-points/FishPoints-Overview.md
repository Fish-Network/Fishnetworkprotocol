
# 🐟 Fish Points

## Reputation System for Capital Coordination

---

## Overview

Fish Points (FP) is a **non-transferable reputation system** designed for Fish Pools.

It measures how users contribute based on:

* **Capital commitment**
* **Participation quality**
* **Real outcomes**

Fish Points are not tokens, rewards, or financial instruments.
They are a **structured signal of trust and contribution**.

---

## Core Model

```text
FP(total) = FP(capital) + FP(participation)
```

* **FP(capital)** → reputation from committed capital over time
* **FP(participation)** → reputation from behavior and outcomes

This creates a balanced system where both **what you commit** and **how you act** matter.

---

### Discount Factor (DF)

Each pool has a per-pool **Discount Factor** that scales the FP earned in that pool.

```text
FP(total) = (FP(capital) + FP(participation)) × DF
```

DF defaults to 1.0× (no change to existing examples). It is set per pool at creation, locked once the pool opens, and bounded by protocol-level minimum/maximum. See `Points.md` for full details.

---

## Why It Matters

Traditional systems reward:

* capital alone, or
* activity alone

Fish Points combine both, and anchor them to **real outcomes**.

This enables:

* better trust signals
* stronger coordination
* transparent performance tracking

---

## How It Works

### 1. Capital Reputation

Users earn reputation by committing capital.

* Larger deposits → more points
* Longer duration → more points
* Stops accruing at:

  * withdrawal
  * or Pool settlement

**Formula (simplified):**

```text
FP(capital) = Deposit × (time held)
```

---

### 2. Participation Reputation

Users earn reputation through **voting and outcomes**.

* Every valid vote earns base points
* Early votes earn more
* Correct votes earn additional bonus
* Accuracy bonus only applies if the Pool successfully settles

**Key idea:**
Participation quality matters—not just participation.

---

### 3. Organizer Reputation

Organizers earn reputation by executing successful Pools.

* Open Pool → +1
* Successful Close → +5
* First Distribution → +25

**Outcome-based design:**

* Activity is rewarded
* Execution is rewarded more
* Real investor outcomes are rewarded most

---

## System Principles

### Outcome-Driven

The largest rewards come from delivering real value.

### Early Signal > Late Consensus

Early, independent decisions are more valuable than following the crowd.

### Capital + Behavior

Reputation reflects both economic commitment and decision-making quality.

### Transparent + Auditable

All reputation is derived from **verifiable system events**.

---

## Anti-Gaming Design

The system includes lightweight safeguards:

* Organizer cooldowns
* Maximum concurrent Pools
* Wallet verification
* Join-before-vote requirements
* Only final vote counts

No penalties or slashing in v1 — this is a **positive reputation system**.

---

## What Fish Points Are

* A reputation layer
* A coordination signal
* A way to measure contribution

---

## What Fish Points Are Not

* Not a token
* Not transferable
* Not redeemable
* Not a financial reward system

---

## Summary

Fish Points transforms:

* capital commitment
* participation quality
* real outcomes

into a **single, structured reputation system** for Fish Pools.

It provides a foundation for:

* trust
* coordination
* performance visibility

in private capital networks.

---

