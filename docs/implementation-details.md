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
address to a `bytes20`, and then convert it to a `bytes32` (which pads the
extra 12 bytes with 0's on the *right*), and then convert the whole thing into
a `uint256`. This means that we have 160 bits that matter on the left, and 96
0's on the right stored in `op`.

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
TODO: Selecting A Random Group
