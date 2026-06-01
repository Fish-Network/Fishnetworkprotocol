# 🐟 Fish Pools

## Reputation-Based Capital Coordination

---

## Overview

Fish Pools are **structured capital coordination environments** where participants come together to:

* contribute capital
* participate in decision-making
* execute investment outcomes

Fish Pools are designed to be:

* transparent
* auditable
* outcome-driven
* reputation-aware

They are the foundational building block of the Fish Network.

---

## Core Idea

Fish Pools combine:

* **capital formation**
* **collective decision-making**
* **structured execution**
* **reputation tracking (via Fish Points)**

This creates a system where:

> capital, participation, and outcomes are all measurable and aligned.

---

## Key Components

### 1. Capital

Participants deposit capital into a Pool.

* contributions are tracked
* capital remains in the Pool until:

  * withdrawal
  * or settlement

Capital is used to:

* support deals
* coordinate allocations
* participate in structured investment workflows

---

### 2. Participation

Participants (Fish) engage in:

* voting on proposals
* evaluating opportunities
* contributing to decision-making

Participation is:

* recorded
* evaluated
* reflected in reputation

---

### 3. Organizer

Each Pool has a single **Organizer**.

The Organizer is responsible for:

* creating the Pool
* managing its lifecycle
* ensuring execution
* delivering outcomes

The Organizer plays a critical role in:

* coordination
* trust
* performance

---

### 4. Outcomes

Pools are designed to produce **real outcomes**, such as:

* completed fundraising rounds
* executed deals
* distributions to participants

Outcomes are the most important signal in the system.

---

## Pool Lifecycle

Each Fish Pool follows a structured lifecycle:

```text
draft → open → active → closed → settled → distributed
```

### Lifecycle States

* **draft**
  Pool is created but not yet active

* **open**
  Deposits are accepted. Voting is NOT yet open. Membership NFTs auto-mint on first deposit.

* **active**
  Deposits are FROZEN. Voting is OPEN. The active-start timestamp anchors the timing-bucket math for voter FP.

* **closed**
  Participation window has ended

* **settled**
  Fundraising threshold met + execution completed

* **distributed**
  Participants receive outcomes (e.g. returns)

---

### Open ≠ Active

The Pool deliberately separates deposits and voting into two distinct phases. Open accepts deposits; Active accepts votes. This prevents the late-deposit-for-early-vote-bonus race condition. The transition between them is a manual organizer action (`activatePool()`) that freezes deposits and opens the round in one step.

---

## Roles

### Organizer

* creates and manages the Pool
* drives execution
* responsible for outcomes

### Fish

* contributes capital
* participates in voting
* earns reputation through actions

---

## Governance Model

Fish Pools use a **simple, structured governance system**:

* one wallet = one vote
* votes are Pool-level
* users can update votes during the round
* only the **final vote** counts

The system emphasizes:

* early participation
* independent decision-making
* alignment with successful outcomes

---

## Reputation Layer

Fish Pools integrate directly with **Fish Points**.

This means:

* capital commitment → builds reputation
* participation → builds reputation
* successful execution → builds reputation

Reputation is:

* non-transferable
* event-driven
* fully auditable

See: `Fish Points (Unredeemable)` for full details.

---

## Design Principles

### Outcome-Driven

The system rewards **real results**, not just activity.

### Transparent

All actions are:

* tracked
* visible
* auditable

### Simple by Default

The system avoids unnecessary complexity:

* two roles (Organizer + Fish)
* clear lifecycle
* straightforward governance

### Reputation-Native

Every meaningful action contributes to a **reputation layer**.

---

## Anti-Gaming Structure

Fish Pools include lightweight constraints to maintain integrity:

* Organizer cooldowns
* limits on concurrent Pools
* participation eligibility requirements
* final-vote-only counting

These rules ensure:

* fairness
* signal quality
* resistance to manipulation

---

## What Fish Pools Enable

Fish Pools unlock:

* coordinated capital formation
* structured group decision-making
* transparent execution
* measurable performance

They provide a foundation for:

* private capital networks
* investment coordination
* reputation-based systems

---

## What Fish Pools Are Not

* Not a token system
* Not a trading platform
* Not a passive investment vehicle
* Not a social feed

Fish Pools are **active coordination environments**, not passive systems.

---

## Example Flow

1. Organizer creates a Pool
2. Pool opens for participation
3. Fish join and deposit capital
4. Fish vote on proposals
5. Pool reaches threshold and closes
6. Pool settles (execution complete)
7. Distribution occurs
8. Reputation updates based on actions

---

## Distribution

### Paginated distribution

`distribute(offset, count)` pays out a slice of depositors per call. Pools with many depositors use multiple `distribute` transactions; the pool transitions to `Distributed` automatically when the last batch completes. The first batch that actually moves money fires the organizer's +25 Fish Points milestone.

---

## Summary

Fish Pools provide a **structured environment for capital coordination** where:

* capital is committed
* decisions are made collectively
* outcomes are delivered
* reputation is built

They are the core infrastructure that enables:

> transparent, outcome-driven coordination in private capital markets.

---
