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

### Branch And Root Deserialization And Serialization
TODO: Branch / Root Serialization and Deserialization

### Joining and Leaving The Pool

Operators join the pool according to two pieces of state: `rightmostLeaf` and
`emptyLeaves`. `rightmostLeaf` is an always-increasing counter that starts at 0
and increases each time an operator needs to join the pool. Eventually,
`rightmostLeaf` will exceed `2,097,152`, which is the size of the leaf layer,
and we'll ignore it forever, and instead rely on `emptyLeaves`.

`emptyLeaves` is an array that is appended to with the position of the operator
who *leaves* the pool. Once `rightmostLeaf` is useless, we `pop` `emptyLeaves`,
insert the new operator in that position, and repeat. We should never run out
of positions with this strategy because the number of leaves far exceeds the
total token supply divided by the minimum stake.

Here's a sample event log with state, using a max leaf length of `4` instead of
`2097152` for brevity.

```
state 1) slots: [-, -, -, -], rightmostLeaf: 0, emptyLeaves: []
event: A joins
state 2) slots: [A, -, -, -], rightmostLeaf: 1, emptyLeaves: []
event: B joins
state 3) slots: [A, B, -, -], rightmostLeaf: 2, emptyLeaves: []
event: C joins
state 4) slots: [A, B, C, -], rightmostLeaf: 3, emptyLeaves: []
event: B leaves
state 5) slots: [A, -, C, -], rightmostLeaf: 3, emptyLeaves: [1]
event: D joins
state 6) slots: [A, -, C, D], rightmostLeaf: 4, emptyLeaves: [1] // rightmostLeaf is forever useless now
event: A leaves
state 7) slots: [-, -, C, D], rightmostLeaf: 4, emptyLeaves: [1, 0]
event: E joins
state 8) slots: [E, -, C, D], rightmostLeaf: 4, emptyLeaves: [1]
```

Each time an operator joins or leaves the pool, we need to update all of the
branches on the path from the operator to the root, as well as the root. The
branch with the operator as a child will have its slot updated with the child's
weight directly. That branch's total weight will change, which will update it's
slot in that branch's parent, and so on, all the way up to the root.

For an in-depth explanation of how this information is structured, refer to the
[Branch and Root Deserialization and
Serialization](#branch-and-root-deserialization-and-serialization) section.

TODO: Selecting A Random Group
