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

[Building Intuition](docs/building-intuition.md) starts the reader from the
problem description and an easy-to-understand naive solution, and then works
its way up to the current design of the sortition pool through a series of
optimizations.

[Implementation Details](docs/implementation-details.md) builds off of the
knowledge in [Building Intuition](docs/building-intuition.md), and gets into
the finer points about the data structure, data (de)serialization, how
operators join/leave the pool, and how it all comes together to select a full
group.

## Important Facts

+ The max number of operators is `2,097,152`

FIXME: fill this in with information about:

+ how long it takes to create a group of 100 operators
+ how much gas it takes

## Safe Use

Miners and other actors that can predict the selection seed (due
to frontrunning the beacon or a public cached seed being used) may be able to
manipulate selection outcomes to some degree by selectively updating the pool.

To mitigate this, application using sortition pool should lock sortition pool
state before seed used for the new selection is known and should unlock the
pool once the selection process is over, keeping in mind potential timeouts and
result challenges.
