# Sortition Pools

Sortition pool is a logarithmic data structure used to store the pool of
eligible operators weighted by their stakes. In the Keep network the stake
consists of staked KEEP tokens. It allows to select a group of operators based
on the provided pseudo-random seed.

Each privileged application has its own sortition pool and is responsible for
maintaining operator weights up-to-date.

## In-Depth Reading

To familiarize yourself with the sortition pool and it's design, we provide

+ [Building Intuition](docs/building-intuition.md)
+ [Implementation Details](docs/implementation-details.md)
+ [Rewards](docs/rewards.md)

[Building Intuition](docs/building-intuition.md) starts the reader from the
problem description and an easy-to-understand naive solution, and then works
its way up to the current design of the sortition pool through a series of
optimizations.

[Implementation Details](docs/implementation-details.md) builds off of the
knowledge in [Building Intuition](docs/building-intuition.md), and gets into
the finer points about the data structure, data (de)serialization, how
operators join/leave the pool, and how it all comes together to select a full
group.

[Rewards](docs/rewards.md) is a deep-dive into how the sortition pool keeps
track of rewards. It features code explanations and walk-throughs of state
transitions for common situations.

## Important Facts

+ The max number of operators is `2,097,152`
+ The sortition pool is for general purpose group selection. Feel free to use
  or fork it!
+ The sortition pool can be [optimistic](#optimisic-group-selection)! The
  on-chain code then is only run in the case that the selection submission is
  challenged.
+ The sortition pool tracks rewards!

## Safe Use

Miners and other actors that can predict the selection seed (due
to frontrunning the beacon or a public cached seed being used) may be able to
manipulate selection outcomes to some degree by selectively updating the pool.

To mitigate this, applications using sortition pool should lock sortition pool
state before seed used for the new selection is known and should unlock the
pool once the selection process is over, keeping in mind potential timeouts and
result challenges.

## Optimistic Group Selection

When an application (like the [Random
Beacon](https://github.com/keep-network/keep-core/tree/main/solidity/random-beacon#group-creation))
needs a new group, sortition is performed off-chain according to the same
algorithm that would be performed on-chain, and the results are submitted
on-chain.

Then, we enter a challenge period where anyone can claim that the submitted
results are inaccurate. If this happens, the on-chain sortition pool runs the
same group selection with the same seed and validates the results.

If the submission was invalid, the challenger is rewarded and the submitter is
punished, and we can accept another submission. If the submission was valid,
the challenger loses out on their gas, and the submitter is unaffected.
