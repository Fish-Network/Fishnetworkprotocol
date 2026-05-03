
# 🐟 Fish Network

## Fish Pools + Fish Points

---

## Overview

Fish Network is a **reputation-based capital coordination system**.

It combines:

* **Fish Pools** → structured environments for capital formation and execution
* **Fish Points** → a non-transferable reputation system

Together, they create a system where:

> capital, participation, and outcomes are measurable, aligned, and transparent.

---

## 🧱 System Architecture

```text id="k2w6o4"
Fish Pools (execution layer)
        ↓
User Actions (capital, voting, outcomes)
        ↓
Fish Points (reputation layer)
        ↓
Reputation Signals (trust, performance, coordination)
```

---

## 🐟 Fish Pools

### The Execution Layer

Fish Pools are where coordination happens.

They allow participants to:

* contribute capital
* vote on decisions
* execute investment outcomes

Each Pool is a **structured, lifecycle-driven environment**.

---

### Pool Lifecycle

```text id="o7q4bn"
draft → open → active → closed → settled → distributed
```

* **open** → Pool becomes active and valid
* **settled** → execution completed successfully
* **distributed** → participants receive outcomes

---

### Roles

#### Organizer

* creates and manages the Pool
* drives execution
* responsible for outcomes

#### Fish

* contributes capital
* participates in voting
* earns reputation

---

### Core Functions

* capital coordination
* governance (voting)
* structured execution
* outcome delivery

---

## 🎯 Fish Points

### The Reputation Layer

Fish Points measure how users contribute within Fish Pools.

They are:

* non-transferable
* non-financial
* wallet-based
* event-driven

---

### Core Model

```text id="b7y8eq"
FP(total) = FP(capital) + FP(participation)
```

---

### FP(capital)

Reputation from capital commitment.

* based on deposit size
* increases with time held
* stops at withdrawal or settlement

---

### FP(participation)

Reputation from behavior and outcomes.

Includes:

* voting participation
* early participation
* voting accuracy
* organizer execution

---

### Organizer Rewards

* Open Pool → +1
* Successful Close → +5
* First Distribution → +25

Largest rewards are tied to **real outcomes**.

---

## 🔁 How They Work Together

Fish Pools generate the activity.
Fish Points measure the contribution.

---

### Flow

1. Organizer creates a Pool
2. Fish join and deposit capital
3. Fish participate in voting
4. Pool reaches outcome (settled + distributed)
5. System records events
6. Fish Points update reputation

---

### Conceptual Loop

```text id="j1kzqs"
Action → Event → Score → Reputation → Future Coordination
```

---

## 🧠 System Principles

### Outcome-Driven

Reputation is tied to real results—not just activity.

### Capital + Participation

Both financial commitment and behavior matter.

### Early Signal > Late Consensus

Early, independent decisions carry more weight.

### Transparent + Auditable

All reputation is derived from verifiable events.

### Simple by Design

* two roles
* clear lifecycle
* minimal rules
* strong signal

---

## 🔍 Transparency & Auditability

The system is fully inspectable:

* every action creates an event
* every event contributes to reputation
* users can trace:

  * capital flows
  * voting behavior
  * outcome history

This enables:

* trust
* verification
* performance tracking

---

## 🛡 Anti-Gaming Design

To maintain integrity:

* Organizer cooldowns
* limits on concurrent Pools
* wallet verification
* join-before-vote requirements
* only final votes count

No penalties in v1—this is a **positive reputation system**.

---

## 🚫 What This Is Not

* Not a token system
* Not a trading platform
* Not a passive investment product
* Not a social feed

---

## 🚀 What This Enables

Fish Network enables:

* coordinated private capital formation
* structured group decision-making
* outcome-based reputation systems
* transparent performance tracking

---

## 🧩 Mental Model

Think of the system as:

* **Fish Pools** = where things happen
* **Fish Points** = how contribution is measured

---

## 🔗 Related Docs

* Fish Pools — execution layer details
* Fish Points — reputation system
* Examples — scoring walkthroughs
* Developer Guide — APIs and integrations

---

## Summary

Fish Network combines:

* structured coordination (Pools)
* measurable contribution (Points)

into a system where:

> capital, participation, and outcomes are aligned through reputation.

---
