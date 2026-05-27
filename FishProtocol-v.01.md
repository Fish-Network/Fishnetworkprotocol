

---

# 🐟 Fish Network's Blockchain Protocol

## Fish Pools + Fish Points

---

## Overview

Fish Network is a **reputation-based capital coordination system**.

It combines:

* **Fish Pools** — structured environments for capital formation and execution
* **Fish Points** — a non-transferable reputation system

Together, they create a system where:

> capital, participation, and outcomes are measurable, aligned, and transparent.

---

## 🧱 System Architecture

```
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

```
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
* builds reputation

---

### Core Functions

* capital coordination
* governance (voting)
* structured execution
* outcome delivery

---

## 🎯 Fish Points (Unredeemable)

### The Reputation Layer

Fish Points measure how users contribute within Fish Pools.

They are:

* non-transferable
* non-financial
* wallet-based
* event-driven

---

### Core Model

```
FP(total) = FP(capital) + FP(participation)
```

---

### FP(capital)

Reputation from capital commitment.

* increases with deposit size
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

The largest rewards are tied to **real outcomes**.

---

## 🔁 How They Work Together

Fish Pools generate activity.
Fish Points measure contribution.

---

### System Flow

1. Organizer creates a Pool
2. Participants join and deposit capital
3. Participants vote on proposals
4. Pool reaches outcome (settled → distributed)
5. System records events
6. Fish Points update reputation

---

### Feedback Loop

```
Action → Event → Score → Reputation → Future Coordination
```

---

## 🧠 Design Principles

### Outcome-Driven

Reputation is tied to real results—not just activity.

### Capital + Participation

Both financial commitment and behavior matter.

### Early Signal > Late Consensus

Early, independent decisions carry more weight.

### Transparent & Auditable

All reputation is derived from verifiable system events.

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

* organizer cooldowns
* limits on concurrent Pools
* wallet verification
* join-before-vote requirements
* only final votes count

No penalties in v1 — this is a **positive reputation system**.

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

* **Fish Pools** = where coordination happens
* **Fish Points** = how contribution is measured

---

## 🔗 Related Docs

* Fish Pools — execution layer(COMING SOON)
* Fish Points (Unredeemable) — reputation system(COMING SOON)
* Examples — scoring walkthroughs(COMING SOON)
* Developer Guide — APIs and integrations(COMING SOON)

---

## Summary

Fish Network combines:

* structured coordination (Pools)
* measurable contribution (Points)

into a system where:

> capital, participation, and outcomes are aligned through reputation.

# Fish Protocol  
**What is Fish Protocol?**

Fish Protocol enables financial institutions, businesses and retail investor communities to build reputation driven composable investment vehicles. By simplifying the capital pooling process we help investors transcend traditional regulatory and geographic boundaries and invest together with confidence. The framework enables fast formation of investment entities coupled with composable private market building blocks, that together represent an investment contract \+ monetary asset that includes economic rules and distribution logic.

**How is this possible?**

Through the simple financial primitive of a [Fish Pool.](https://docs.google.com/document/d/1nReYvTryOVQLICecWZCuBngz_ZWslrBR2CNxEyYWZ8E/edit?usp=docs_web&ouid=113988110484830156651)

We use Fish Pools as the standardized core component, where additional functionality and compliance logic is layered on top by Fish Network and other businesses. This way we maintain the efficiency and simplicity of the capital pooling system for a single asset, which sets the foundation for more complex investment vehicles to be built using one or many individual Fish Pools.

**What does this enable?**

By coupling Fish Pools with existing techniques found in both traditional and crypto derivatives and prediction markets, we unlock a new structure to expand liquidity in private markets. This structure enables anyone who has an opinion, to also have an **investment position, without ever owning the underlying assets. This enables people to trade on outcomes** tied to the investment performance in private markets.

**Why does this matter?**

Derivatives on private markets do not currently exist. This unlocks future liquidity through synthetic exposure to the underlying private market assets.

**What about investor privacy and trust concerns?**

Markets are transparent, but all investor information is private by default. All capital is routed through stablecoins and smart contracts for transparency and auditability. 

**What are Fish Points? What aren’t Fish Points?**

Fish points are not a narrative-driven, gamified social all-in-one investor reputation score. Fish Points are the scorekeeping ledger for an evidence driven attestation network, where off-chain documents and records are verified and subsequently etched on-chain. 

# **Fish Pool FAQs**

Fish Network has built Fish Protocol — capital pooling infrastructure applied directly to financial services use cases, venture capital specifically, and private markets broadly.

Basic capital pooling infrastructure should be a right, not a privilege. We released Fish Protocol open source so anyone can pool capital for use cases outside of financial services, such as social reasons or non-profits.  

**What is an example use case of Fish Protocol?**

A social example use case could be pooling capital to collectively split the cost to cover a friend's funeral.

**What are the fees to use Fish Protocol?**

There are none. Fish Network believes capital pooling infrastructure should be available to anyone.

**Do I have to use a legal entity to organize a fish pool?**

No. A legal entity accompanying your fish pool is highly recommended for use cases involving investing and financial services, but for pooling capital with friends for social purposes, it may not be needed.

**What if I want to customize my own version of a Fish Pool and do this on my own?**

For custom fish pools outside of private markets in financial services, using our standard PoolCore() and/or PoolFactory() contracts, we charge no fees. We just ask that you give us credit for providing the infrastructure\!

**What type of assets are currently supported with Fish pools?**

The fish pool creation framework is open-source, so theoretically, any asset could be possible under any jurisdiction.

**How are distributions calculated?**

Basic accounting of distributions is included in the PoolFactory() / PoolCore contract.

Advanced distribution logic can be programmed directly into the Config file if needed.

**How are withdrawals processed on fish protocol?**

Users must claim their profits or distributions directly and will be notified by the Organizer when available.
