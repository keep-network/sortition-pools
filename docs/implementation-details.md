TODO: Introduce the document

### Structure
The data structure of the sortition pool is a root node, which is a single
`uint256`, followed by 6 layers of branch nodes, followed by a leaf layer. Each
branch node is a `uint256`, and the branch structure is implemented as a
`mapping(uint256 => mapping(uint256 => uint256))`. The first index represents
the layer, and the second index represents the position within the layer.

The first branch layer has 8 branches, and every subsequent layer has 8x the number of branches as the previous layer, so 

1) node layer: 1
2) branch layer 1: 8
3) branch layer 2: 64
4) branch layer 3: 512
5) branch layer 4: 4,096
6) branch layer 5: 32,768
7) branch layer 6: 262,144
8) leaf layer: 2,097,152

### Leaf Serialization and Deserialization

```
function make(
  address _operator,
  uint256 _creationBlock,
  uint256 _id
) internal pure returns (uint256) {
  assert(_creationBlock <= type(uint64).max);
  assert(_id <= type(uint32).max);
  uint256 op = uint256(bytes32(bytes20(_operator)));
  uint256 uid = _id & ID_MAX;
  uint256 cb = (_creationBlock & BLOCKHEIGHT_MAX) << ID_WIDTH;
  return (op | cb | uid);
}
```

The `Leaf.make` takes in an operator address, the block it was created in, and
a monotonically increasing id for unique operators. We convert the operator
address to a bytes20, and then convert it to a bytes32 (which pads the extra 12
bytes with 0's on the *right*), and then convert the whole thing into a
`uint256`. This means that we have 160 bits that matter on the left, and 96 0's
on the right stored in `op`.

`ID_MAX = 2^32 - 1` is represented as 32 1's, which as a `uint256` is 224 0's
followed by 32 1's. The bitwise `&` clears out everything but the last 32
significant bits of `_id`, leaving us with 224 0's and 32 significant bits
stored in `uid`.

`BLOCKHEIGHT_MAX = 2^64 - 1` is represented as 64 1s, which as a `uint256` is
192 0's followed by 64 1's. the bitwise `&` clears out everything but the last
64 significant bits of `_creationBlock`, and then we shift those bits to the
left by `ID_WIDTH = 32` bits. This gives us 160 0's, 64 significant bits, and
32 zeros stored in `cb`.

Then, we run `op | cb`. `op` has 160 significant bits on the left, and 96 0s on
the right, and `cb` has 160 0s on the left, 64 significant bits, and then 32
zeros. The intermediate result has 224 significant bits followed by 32 0's with
no collisions so far. We combine that result with `| uid`, which has 224 0s,
and 32 significant bits, leaving us with 256 significant bits and no
collisions.

The resulting number is meaningless! Rather, it is only useful as a storage
mechanism. If we want to know the operator we can look at the first 160 bits or
the last 32 bits. If we want to know the creation block, we should look at bits
`[160, 224)` (which we can do by right-shifting and then applying a bitwise
`&`).

TODO: Branch / Root Serialization and Deserialization
TODO: Joining and Leaving The Pool

### Selecting A Random Group

To select a random group of of operators from the pool size `N`, we construct
an array of size `N` to house the result, and then populate it, one random
operator at a time, with replacement.

We start with a seed provided from the [random
beacon](https://github.com/keep-network/keep-core/tree/main/solidity/random-beacon)
and use that seed in combination with the total weight of the root node,
calculatable by summing the weight of the slots: see [Branch And Root
Deserialization And
Serialization](#branch-and-root-deserialization-and-serialization) to generate
a random uniform integer in `[0, root.totalWeight)`, as well as the next random
seed for the next random operator. In order to generate this next random seed,
we're using 
```
newState = keccak256(abi.encodePacked(newState, address(this)));
```
which, according to [A Pseudorandom Number Generator with KECCAK Hash Function
by A. Gholipour and S. Mirzakuchak](http://www.ijcee.org/papers/439-JE503.pdf),
has "excellent pseudo randomness".

Once we have our random integer, we are able to descend down the tree according
to the algorithm outlined in [building intuition](building-intuition.md).

```
function pickWeightedLeaf(uint256 index, uint256 _root)
  internal
  view
  returns (uint256 leafPosition)
{
  uint256 currentIndex = index;
  uint256 currentNode = _root;
  uint256 currentPosition = 0;
  uint256 currentSlot;

  require(index < currentNode.sumWeight(), "Index exceeds weight");

  // get root slot
  (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);

  // get slots from levels 2 to 7
  for (uint256 level = 2; level <= LEVELS; level++) {
    currentPosition = currentPosition.child(currentSlot);
    currentNode = branches[level][currentPosition];
    (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);
  }

  // get leaf position
  leafPosition = currentPosition.child(currentSlot);
}

function pickWeightedSlot(uint256 node, uint256 index)
  internal
  pure
  returns (uint256 slot, uint256 newIndex)
{
  unchecked {
    newIndex = index;
    uint256 newNode = node;
    uint256 currentSlotWeight = newNode & SLOT_MAX;
    while (newIndex >= currentSlotWeight) {
      newIndex -= currentSlotWeight;
      slot++;
      newNode = newNode >> SLOT_WIDTH;
      currentSlotWeight = newNode & SLOT_MAX;
    }
    return (slot, newIndex);
  }
}
```

At a particular root/branch node, we inspect the right-most 32 bits by applying
a bitwise `&` against `2^32 - 1`, which leaves only the last 32 bits as
potentially non-zero.

If this quantity if greater than our random number, we found our path of
descent and repeat the process at the next layer. If it isn't, then we increase
our slot counter, decrease our random number by the quantity, and shift our
number over 32 bits to the right and repeat.

Eventually we will find a slot that exceeds our random number and be able to
descend to the next layer where the process repeats until we get to the leaf
layer where the task is finished.

We record our chosen operator in the result list, use the fresh seed from
`keccak256` to generate a new random number and new seed, and repeat until we
have a full group.
