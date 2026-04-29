# 📊 Fish Points — Example Scoring Walkthroughs

This document provides concrete examples of how Fish Points are calculated in real scenarios.

These examples are designed to help both technical and non-technical readers understand:

* how points are earned
* how timing and accuracy affect outcomes
* how capital contributes over time

---

# 1. Organizer Example

## Scenario

An Organizer creates and successfully runs a Pool.

### Actions

1. Opens Pool → +1 FP
2. Pool reaches threshold and settles → +5 FP
3. First distribution to investors completes → +25 FP

### Total

FP_participation = 1 + 5 + 25 = 31

### Interpretation

* Opening the Pool has small value
* Closing it has meaningful value
* Delivering returns has the highest value

---

# 2. Fish Voting — Early & Correct

## Scenario

A Fish:

* joins before voting starts
* votes early (10% into the round)
* votes correctly
* Pool successfully settles

### Step 1 — Determine timing

progress = 10% → Early bucket → 1.5x multiplier

### Step 2 — Apply formula

Base = 1
Accuracy Bonus = 2

FP_vote = (1 + 2) × 1.5 = 4.5

### Result

FP_participation = 4.5

### Interpretation

* Early + correct = highest reward

---

# 3. Fish Voting — Late but Correct

## Scenario

A Fish:

* votes at 90% of round duration
* votes correctly
* Pool settles

### Step 1 — Timing

progress = 90% → Late bucket → 0.75x

### Step 2 — Accuracy eligibility

Late votes (final 20%) do NOT receive accuracy bonus.

### Step 3 — Apply formula

FP_vote = 1 × 0.75 = 0.75

### Result

FP_participation = 0.75

### Interpretation

* Being correct late matters less
* System discourages copying consensus

---

# 4. Fish Voting — Early but Incorrect

## Scenario

A Fish:

* votes early (20%)
* votes incorrectly
* Pool settles

### Step 1 — Timing

progress = 20% → Early → 1.5x

### Step 2 — Apply formula

FP_vote = 1 × 1.5 = 1.5

### Result

FP_participation = 1.5

### Interpretation

* Participation still rewarded
* Accuracy is what multiplies impact

---

# 5. Fish Voting — Pool Never Settles

## Scenario

A Fish:

* votes early
* votes correctly
* Pool fails to settle

### Rule

Accuracy bonus is only awarded if Pool reaches settled.

### Calculation

FP_vote = Base × Timing
= 1 × 1.5 = 1.5

### Result

FP_participation = 1.5

### Interpretation

* No outcome → no accuracy bonus
* System rewards real outcomes only

---

# 6. Capital Example — Standard Case

## Scenario

A Fish:

* deposits $1,000
* holds for 60 days
* Pool settles

### Step 1 — Calculate duration

days_held = 60

### Step 2 — Apply formula

FP_capital = 1000 × (60 / 30)
FP_capital = 1000 × 2
FP_capital = 2000

### Result

FP_capital = 2000

### Interpretation

* Capital doubles reputation over 2 months
* Duration matters as much as size

---

# 7. Capital Example — Early Withdrawal

## Scenario

A Fish:

* deposits $1,000
* withdraws after 15 days
* Pool later settles

### Step 1 — Accrual stops at withdrawal

days_held = 15

### Step 2 — Apply formula

FP_capital = 1000 × (15 / 30)
FP_capital = 1000 × 0.5
FP_capital = 500

### Result

FP_capital = 500

### Interpretation

* Early exit reduces reputation
* Staying in longer is rewarded

---

# 8. Combined Example (Full User)

## Scenario

A Fish:

* deposits $2,000 for 30 days
* votes early and correctly

### Capital

FP_capital = 2000 × (30 / 30) = 2000

### Participation

FP_vote = (1 + 2) × 1.5 = 4.5

### Total

FP_total = 2000 + 4.5 = 2004.5

### Interpretation

* Capital dominates magnitude
* Participation adds signal quality
* Both matter

---

# 9. Organizer + Fish Hybrid Example

## Scenario

User is both:

* Organizer of a Pool
* Participant in another Pool

### Organizer Earnings

Open = +1
Close = +5
Distribution = +25

Total = 31

### Fish Participation

Early correct vote = 4.5

### Capital

Deposit = 1000 for 30 days → 1000 FP

### Final Total

FP_total = 31 + 4.5 + 1000 = 1035.5

---

# 10. Key Takeaways

## What matters most

1. Capital scale
2. Holding duration
3. Successful outcomes
4. Early participation
5. Accuracy

## What matters least

* Late participation
* Short-term capital
* Passive behavior

---

# Final Mental Model

Think of Fish Points as:

Reputation = Commitment + Judgment + Execution

Where:

* Commitment = capital
* Judgment = voting
* Execution = organizing

---
