A good way to understanding the sortition pool design is to understand the
original problem and naive approach, and then understand the optimizations away
from that naive solution.

### Original Problem and Naive Approach

Say that we have a list of operators like `[Alice, Bob, Carol, David]`, and
each operator has a different amount of stake in the pool `{Alice: 30, Bob: 20:
Carol: 40: David: 50}`. We need to select a group of operators (say, 3), where
each operator selected has a chance to be selected equal to their *portion* of
the total amount of stake in the pool. It's okay to select one operator
multiple times. We might end up with a group that looks like `[David,
Carol, David]`.

In our example, the chance that we select Alice is `30 / (30 + 20 + 40 + 50) =
0.214`.

In order to select a single *slot* in our group, we might write something simple like:

```
function chooseOperator(operators) {
  const operatorNames = Object.keys(operators)

  let totalWeight = 0
  for (let i = 0; i < operatorNames.length; i++) {
    const operatorName = operatorNames[i]
    totalWeight += operators[operatorName]
  }

  let randomValue = Math.floor(Math.random() * totalWeight)

  let chosenOperator = undefined
  for (let i = 0; i < operatorNames.length; i++) {
    const operatorName = operatorNames[i]
    const operatorStake = operators[operatorName]
    if (operatorStake > randomValue) {
      chosenOperator = operatorName
      break;
    } else {
      randomValue -= operatorStake
    }
  }
  return chosenOperator
}
chooseOperator({"Alice": 30, "Bob": 20, "Carol": 40, "David": 50})
```

In english, we figure out the total weight of the pool, and then generate a
random number in `[0, totalWeight)`. Then, we assign a sort of cumulative
distribution to each of the operators: Alice is picked if that random number is
in `[0, 30)`, Bob is picked if the random number is in `[20, 50)`, Carol is
picked if the random number is in `[50, 90)`, and David is picked if the random
number is in `[90, 140)`.

Say our random number was 64. We know that's in Carol's range, but how do we
determine that? First, we check if 64 > Alice's 30, and it isn't, so we
subtract 30 from 64 and move to Bob. Bob's 20 still isn't greater than the
remaining 34, so we subtract 20 and move to Carol. Carol's 40 is greater than
the remaining 14 so we're finished.

If we need to generate `numOperators` amount of operators, then we just loop:

```
function chooseOperators(operators, numOperators) {
let group = []
  for (let i = 0; i < numOperators; i++) {
    group.push(chooseOperator(operators))
  }
  return group
}
chooseOperators({"Alice": 30, "Bob": 20, "Carol": 40, "David": 50}, 3)
```

This just works! In applications where performance doesn't matter and we don't
care about the cost of reading or writing data to memory, this is probably good
enough. On ethereum, looping through thousands of operators a hundred times to
get a 100-person group is *extremely* expensive, so we need to optimize.

### Binary Trees

Say that we have 1000 operators, each of which has 1 stake. In the average
case, we need to iterate through 500 operators, and in the worst case, we need
to iterate through all 1000 of them. We can do better!

If we store the operators in a binary tree where each branch is the sum of the
weight of the branches below it, and the leaves are the individual operators
with their individual weights, then we have a bigger data structure that is
*much* faster to search.

We can represent 2 operators with a 1-layer tree, 4 operators with a 2-layer
tree, 8 operators with a 3-layer, and `2^n` operators with a `n`-layer tree. In
order to represent our 1000 operators, we need 10 layers.

Once this data structure is created, we can execute the following algorithm:

1. Generate a random number: `Math.floor(Math.random() * rootValue)`, since the root is the total weight
2. If the left number is greater than the random number, take the branch. Go to Step 2.
3. Take the right branch and decrease the random number by the left number. Go to Step 2.

Eventually you hit a leaf node, and when you do, that's your operator. This
algorithm is able to execute in `log_base_2(operators.size)` time (the number
of layers), which is a massive improvement over linear time.

Here's a worked example with our original operator team. The names have been abbreviated to save space:

```
          ┌─────────────┐
        ┌─┤A+B+C+D: 140 ├───┐
        │ └─────────────┘   │
    ┌───┴────┐          ┌───┴────┐
   ┌┤A+B: 50 │         ┌┤C+D: 90 │
   │└──────┬─┘         │└──────┬─┘
┌──┴───┐┌──┴───┐    ┌──┴───┐┌──┴───┐
│A: 30 ││B: 20 │    │C: 40 ││D: 50 │
└──────┘└──────┘    └──────┘└──────┘
```

Say we generate the random number `62`. That's greater than or equal to the
left node of `50`, so we take the right branch: `C+D` and reduce our number to
`62-50=12`. We observe that `40 > 12`, so `C` (Carol) is our operator.

### Storing Multiple Operators In One `uint256`

We're most of the way there, but each read operation is expensive. At ~2000
operators, we'd need 11 layers, which is 11 reads (and keep in mind, we need to
repeat this process a number of times equal to the group size). To further
optimize we can leverage storing the stake as a 32-bit number inside of a
uint256, which ultimately allows us to store `256/32=8` operator's stakes in a single
uint256.

To reason about this in decimal I'll use digits instead of bits, and 4 slots instead of 8 to keep things compact.

Imagine that we know that the biggest numbers we need to work with are 4 digits
long, but we're allowed to store it in a number that is *16* digits long. We
might often write that an operator's stake is `42`, but if we're using a
16-digit number, that would be `0000000000000042`, and we're wasting all of
those zeroes.

Instead, we can say "every 4 digits belong to an operator", and then represent
our original 4 operators like: `0030002000400050`. Then, we restructure the
tree. Each layer has 4 times the number of nodes as the previous layer, and
each leaf represents 4 operators. To figure out which node we should
descend into next, we solve the naive version of the problem, but by
bit-shifting the number rather than by iterating through a list.

Here's an example with 16 Operators and their associated stake:

Stakes:
```
Alice: 1
Bob: 2
Carol: 3
David: 4
Eric: 5
Fiona: 6
Greg: 7
Helga: 8
Isaac: 9
Juliet: 10
Kevin: 11
Leah: 12
Mike: 13
Noelle: 14
Oscar: 15
Pearl: 16

                                          ┌───────────────────────────┐
             ┌───────────────────────────┌┤0010002600420058, sum: 136 ├──────────────────────────┐
             │                           │└──────────────────────────┬┘                          │
┌────────────┴─────────────┐┌────────────┴─────────────┐┌────────────┴─────────────┐┌────────────┴─────────────┐
│A,B,C,D: 0001000200030004 ││E,F,G,H: 0005000600070008 ││I,J,K,L: 0009001000110012 ││M,N,O,P: 0013001400150016 │
└──────────────────────────┘└──────────────────────────┘└──────────────────────────┘└──────────────────────────┘
```

Say we generate a random number in `[0, 136)` and get 81. We shift through the digits of the top group one at a time:

+ 10 <= 81, so we shift and subtract to 71
+ 26 <= 71, so we shift and subtract to 45
+ 42 <= 45, so we shift and subtract to 3
+ 58 > 3, so we descend into the 4th group.
+ 13 > 3, so we know that our operator is the first member of group 4: Mike.

We can double check this by reconstructing the naive table:
```
Alice: [0, 1)
Bob: [1, 3)
Carol: [3, 6)
David: [6, 10)
Eric: [10, 15)
Fiona: [15, 21)
Greg: [21, 28)
Helga: [28, 36)
Isaac: [36, 45)
Juliet: [45, 55)
Kevin: [55, 66)
Leah: [66, 78)
Mike: [78, 91)
Noelle: [91, 105)
Oscar: [105, 120)
Pearl: [120, 136)
```
And we observe that 81 falls into Mike's range!

The example uses digits instead of bits, and uses 4 operators per storage slot
number instead of 8, but the *intuition* is the same. Even though we're having
to iterate through operators less efficiently than in the binary tree example,
we're interacting far less with storage (especially "read" calls), which ends
up being the main gas bottleneck.

### Token Precision

Clever readers might point out that tokens have 18 decimals of precision and
the total supply of T tokens is 10B, which takes `log_base_2(1e28) = 94` bits
to store. The good news for us is that we only care about generating relative
probability, and we have a minimum stake, which makes 32 bits enough for
practical purposes. As in, if you have `10000.000000000000000001` tokens, all
the system is doing is using that amount to generate a probability that you are
selected. So yes, by losing precision on the token amounts we lose precision on
the relative probabilities, but the precision loss is so insificant as to be
irrelevant.
