### Rewards

The rewards implementation is a weight-based pool. When the pool receives
rewards, an operator's share of those rewards is equal to their share of the
pool.

The pool provides 3 basic functions:

+ updating an operator's weight in the pool
+ granting the pool rewards
+ withdrawing an operator's rewards

On top of those basic functions, higher level concepts can be constructed. For
example, joining the pool is implemented as updating an operator's weight from
0 to positive. Leaving the pool is implemented as updating the operator's
weight from positive to 0.

In order to accomplish these main functions, we create 3 pieces of state:

```
struct OperatorRewards {
  uint96 accumulated;
  uint96 available;
  uint32 weight;
}
uint96 internal globalRewardAccumulator; // (1)
uint96 internal rewardRoundingDust; // (2)
mapping(uint32 => OperatorRewards) internal operatorRewards; // (3)
```

The (1) `globalRewardAccumulator` represents how much reward a 1-`weight`
operator would have accumulated since genesis. Since we're working in integers,
and since rewards won't always be cleanly divisible by the pool weight, there
carry-over, which is stored in (2) `rewardRoundingDust`.

Finally, the (3) `operatorRewards` keep track of each operator's individual
state indexed by their `id`. An operator's `accumulated` value represents a
snapshot of the `globalRewardAccumulator` at the time they were last updated.
Their `available` value represents how much reward is available for withdraw.
Their `weight` is their weight in the pool.

To see how all of these pieces of state interact, we can go through some
event logs.

#### Join -> Reward -> Withdraw
```
event 1) Alice (id 0) joins the pool with weight 10
event 2) 123 rewards are granted to the pool
event 3) Alice withdraws their rewards
```

We start at a fresh state:
```
globalRewardAccumulator: 0 
rewardRoundingDust: 0
operatorRewards: {}
```

Joining the pool is handled with `updateOperatorRewards(0, 10)` (some
complexity abridged to be introduced later)
```
function updateOperatorRewards(uint32 operator, uint32 newWeight) internal {
  uint96 acc = globalRewardAccumulator;
  OperatorRewards memory o = operatorRewards[operator];
  uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
  o.available += accruedRewards;
  o.accumulated = acc;
  o.weight = newWeight;
  operatorRewards[operator] = o;
}
```

Following the math, we get:
```
acc = 0
o = {accumulated: 0, available: 0, weight: 0}
accruedRewards = (0 - 0) * 0 = 0
o.available = 0 + 0 = 0
o.accumulated = 0
o.weight = 10
operatorRewards: {0: {accumulated: 0, available: 0, weight: 10}}

// new state
globalRewardAccumulator: 0 
rewardRoundingDust: 0
operatorRewards: {0: {accumulated: 0, available: 0, weight: 10}}
```

Ever time an operator is updated, they accrue rewards equal to however much the
`globalRewardAccumulator` accrued in between now and the last time they were
updated, multiplied by their weight (since the acccumulator has a weight of 1).
We use that to inform how many rewards are available to them and then update
their snapshot of the accumulator state and their weight.

Next, 123 rewards are granted to the pool. We call `addRewards(123, 10)`

```
function addRewards(uint96 rewardAmount, uint32 currentPoolWeight) internal {
  require(currentPoolWeight >= 0, "No recipients in pool");

  uint96 totalAmount = rewardAmount + rewardRoundingDust;
  uint96 perWeightReward = totalAmount / currentPoolWeight;
  uint96 newRoundingDust = totalAmount % currentPoolWeight;

  globalRewardAccumulator += perWeightReward;
  rewardRoundingDust = newRoundingDust;
}
```

Following the math, we get: 
```
totalAmount = 123 + 0 = 123
perWeightReward = 123 / 10 = 12
newRoundingDust = 123 % 10 = 3
globalRewardAccumulator = 0 + 12 = 12
rewardRoundingDust = 3

// new state
globalRewardAccumulator: 12 
rewardRoundingDust: 3
operatorRewards: {0: {accumulated: 0, available: 0, weight: 10}}
```

Whenever rewards are distributed, we *only* update `globalRewardAccumulator`
and `rewardRoundingDust`, never any of the operators. Those are only updated
lazily via `updateOperatorRewards`. Note that at this point, alice's
accumulator is 12 rewards behind the global accumulator!

In order to Alice to withdraw her rewards, she shoud *update* herself first,
since her `available` state is `0`. So, first we call `updateOperatorRewards(0, 10)`

```
acc = 12
o = {accumulated: 0, available: 0, weight: 10}
accruedRewards = (12 - 0) * 10 = 120
o.available = 0 + 120 = 120
o.accumulated = 12
o.weight = 10
operatorRewards: {0: {accumulated: 12, available: 120, weight: 10}}

// new state
globalRewardAccumulator: 12 
rewardRoundingDust: 3
operatorRewards: {0: {accumulated: 12, available: 120, weight: 10}}
```

Some amount of reward (an amount between 0 and the total operator weight) will
be unavailable for withdraws due to how the `rewardRoundingDust` works. In
threshold, the weight precision is 1 weight = 1 T, (1e18 divisor), but rewards
are represented with full precision (1e18), so numerically, even small rewards
should greatly exceed the total pool weight.

Alice is now ready to withdraw! We call `withdrawOperatorRewards(0)`

```
function withdrawOperatorRewards(uint32 operator)
  internal
  returns (uint96 withdrawable)
{
  OperatorRewards storage o = operatorRewards[operator];
  withdrawable = o.available;
  o.available = 0;
}

// new state
globalRewardAccumulator: 12 
rewardRoundingDust: 3
operatorRewards: {0: {accumulated: 12, available: 0, weight: 10}}
```

This returns `120` to the caller, and sets Alice's available rewards to 0. The
`Rewards.sol` code isn't responsible for handling any token transaction, only
keeping track of the rewards state. That `120` amount is handled by the
`SortitionPool`, to send Alice the appropriate amount of tokens.

State + Event Logs:
```
event 1) pool is created
globalRewardAccumulator: 0 
rewardRoundingDust: 0
operatorRewards: {}

event 2) Alice (id 0) joins the pool with weight 10 
globalRewardAccumulator: 0 
rewardRoundingDust: 0
operatorRewards: {0: {accumulated: 0, available: 0, weight: 10}}

event 3) 123 rewards are granted to the pool
globalRewardAccumulator: 12 
rewardRoundingDust: 3
operatorRewards: {0: {accumulated: 0, available: 0, weight: 10}}

event 4) Update Alice
globalRewardAccumulator: 12 
rewardRoundingDust: 3
operatorRewards: {0: {accumulated: 12, available: 120, weight: 10}}

event 5) Withdraw Alice's Rewards
globalRewardAccumulator: 12 
rewardRoundingDust: 3
operatorRewards: {0: {accumulated: 12, available: 0, weight: 10}}
return: 120
```

#### Two Operators With Offset Rewards
State + Event Logs:
```
event 1) pool is created
globalRewardAccumulator: 0 
rewardRoundingDust: 0
operatorRewards: {}

event 2) Alice (id 0) joins the pool with weight 10
globalRewardAccumulator: 0 
rewardRoundingDust: 0
operatorRewards: {0: {accumulated: 0, available: 0, weight: 10}}

event 3) 123 rewards are granted to the pool
globalRewardAccumulator: 12 
rewardRoundingDust: 3
operatorRewards: {0: {accumulated: 0, available: 0, weight: 10}}

event 4) Bob (id 1) joins the pool with weight 20
globalRewardAccumulator: 12 
rewardRoundingDust: 3
operatorRewards: {
  0: {accumulated: 0, available: 0, weight: 10}
  1: {accumulated: 12, available: 0, weight: 20}
}

event 5) 321 rewards are granted to the pool
globalRewardAccumulator: 22
rewardRoundingDust: 24
operatorRewards: {
  0: {accumulated: 0, available: 0, weight: 10}
  1: {accumulated: 12, available: 0, weight: 20}
}

event 6) Update Alice
globalRewardAccumulator: 22
rewardRoundingDust: 24
operatorRewards: {
  0: {accumulated: 22, available: 220, weight: 10}
  1: {accumulated: 12, available: 0, weight: 20}
}

event 7) Withdraw Alice's rewards
globalRewardAccumulator: 22
rewardRoundingDust: 24
operatorRewards: {
  0: {accumulated: 22, available: 0, weight: 10}
  1: {accumulated: 12, available: 0, weight: 20}
}
return: 220

event 8) Update Bob
globalRewardAccumulator: 22
rewardRoundingDust: 24
operatorRewards: {
  0: {accumulated: 22, available: 0, weight: 10}
  1: {accumulated: 22, available: 200, weight: 20}
}

event 9) Withdraw Bob's Rewards
globalRewardAccumulator: 22
rewardRoundingDust: 24
operatorRewards: {
  0: {accumulated: 22, available: 0, weight: 10}
  1: {accumulated: 22, available: 0, weight: 20}
}
return 200
```

In theory, Alice should be given 100% of the first `123` reward, and then 1/3
of the `321` reward coming out to a total of 230, which is 51.8% of the
rewards. Bob should only receive 2/3 of the 321 reward coming to a total of
214, which is 48.2%. Since the reward amounts are close to the weight amounts,
the dust is significant enough to be impactful here.

A total of 420 rewards were withdrawn by Alice and Bob (the other 24 are
marooned in `rewardRoundingDust`). The higher the reward amount is relative to
the weight amount, the less this is significant.

#### Eligibility

In addition to the above functions, we want to be mark operators as
"ineligable" for rewards, temporarily. In practice, if Alice and Bob both have
10 weight in the pool and 100 rewards are added while Bob is ineligable, Alice
gets 50, Bob gets 0, and the pool owner is able to retrieve those 50 that Bob
would have gotten at a later date.

In order to accomplish this, we need two more pieces of state:

```
uint96 public ineligibleEarnedRewards;
struct OperatorRewards {
  uint32 ineligibleUntil;
}
```

We keep track of the total amount of reward that operators accumulated while
they were ineligable, and each operator keeps track of when they're allowed to
be eligible again. If `ineligibleUntil == 0`, the operator is eligible.

That means that `updateOperatorRewards` gets a modification:
```
function updateOperatorRewards(uint32 operator, uint32 newWeight) internal {
  uint96 acc = globalRewardAccumulator;
  OperatorRewards memory o = operatorRewards[operator];
  uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
  if (o.ineligibleUntil == 0) {
    o.available += accruedRewards;
  } else {
    ineligibleEarnedRewards += accruedRewards;
  }
  o.accumulated = acc;
  o.weight = newWeight;
  operatorRewards[operator] = o;
}
```

We replaced `o.available += accruedRewards;` with
```
    if (o.ineligibleUntil == 0) {
      o.available += accruedRewards;
    } else {
      ineligibleEarnedRewards += accruedRewards;
    }
```
If the operator is eligible, they accrue rewards, otherwise,
`ineligibleEarnedRewards` accrues those rewards instead.

Finally, the contract owner needs a way to extract ineligable rewards:
```
function withdrawIneligibleRewards() internal returns (uint96 withdrawable) {
  withdrawable = ineligibleEarnedRewards;
  ineligibleEarnedRewards = 0;
}
```

The rest is managing eligibility properly - methods that set and restore a
operator's eligibility, and to make sure that doing so properly updates the
operator's state.

State + Event Logs
```
event 1) pool is created
globalRewardAccumulator: 0 
rewardRoundingDust: 0
ineligibleEarnedRewards: 0
operatorRewards: {}

event 2) Alice (id 0) joins the pool with weight 10
globalRewardAccumulator: 0 
rewardRoundingDust: 0
ineligibleEarnedRewards: 0
operatorRewards: {0: {accumulated: 0, available: 0, weight: 10, ineligibleUntil: 0}}

event 3) 123 rewards are granted to the pool
globalRewardAccumulator: 12 
rewardRoundingDust: 3
ineligibleEarnedRewards: 0
operatorRewards: {0: {accumulated: 0, available: 0, weight: 10, ineligibleUntil: 0}}

event 4) Bob (id 1) joins the pool with weight 20
globalRewardAccumulator: 12 
rewardRoundingDust: 3
ineligibleEarnedRewards: 0
operatorRewards: {
  0: {accumulated: 0, available: 0, weight: 10, ineligibleUntil: 0}
  1: {accumulated: 12, available: 0, weight: 20, ineligibleUntil: 0}
}

event 5) Bob is set as ineligable until 100000 seconds from now
globalRewardAccumulator: 12 
rewardRoundingDust: 3
ineligibleEarnedRewards: 0
operatorRewards: {
  0: {accumulated: 0, available: 0, weight: 10, ineligibleUntil: 0}
  1: {accumulated: 12, available: 0, weight: 20, ineligibleUntil: event5-time + 10000}
}

event 6) 321 rewards are granted to the pool
globalRewardAccumulator: 22
rewardRoundingDust: 24
ineligibleEarnedRewards: 0
operatorRewards: {
  0: {accumulated: 0, available: 0, weight: 10, ineligibleUntil: 0}
  1: {accumulated: 12, available: 0, weight: 20, ineligibleUntil: event5-time + 10000}
}

event 7) Update Alice
globalRewardAccumulator: 22
rewardRoundingDust: 24
ineligibleEarnedRewards: 0
operatorRewards: {
  0: {accumulated: 22, available: 220, weight: 10, ineligibleUntil: 0}
  1: {accumulated: 12, available: 0, weight: 20, ineligibleUntil: event5-time + 10000}
}

event 8) Withdraw Alice's rewards
globalRewardAccumulator: 22
rewardRoundingDust: 24
ineligibleEarnedRewards: 0
operatorRewards: {
  0: {accumulated: 22, available: 0, weight: 10, ineligibleUntil: 0}
  1: {accumulated: 12, available: 0, weight: 20, ineligibleUntil: event5-time + 10000}
}
return: 220

event 9) Update Bob
globalRewardAccumulator: 22
rewardRoundingDust: 24
ineligibleEarnedRewards: 200
operatorRewards: {
  0: {accumulated: 22, available: 0, weight: 10, ineligibleUntil: 0}
  1: {accumulated: 22, available: 0, weight: 20, ineligibleUntil: event5-time + 10000}
}

event 10) Withdraw Ineligable Rewards
globalRewardAccumulator: 22
rewardRoundingDust: 24
ineligibleEarnedRewards: 0
operatorRewards: {
  0: {accumulated: 22, available: 0, weight: 10, ineligibleUntil: 0}
  1: {accumulated: 22, available: 0, weight: 20, ineligibleUntil: event5-time + 10000}
}
return: 200
```
