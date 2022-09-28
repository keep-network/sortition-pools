pragma solidity 0.8.17;

import "../Leaf.sol";

contract LeafStub {
  function make(
    address operator,
    uint256 creationBlock,
    uint256 id
  ) public pure returns (uint256) {
    return Leaf.make(operator, creationBlock, id);
  }

  function operator(uint256 leaf) public pure returns (address) {
    return Leaf.operator(leaf);
  }

  function creationBlock(uint256 leaf) public pure returns (uint256) {
    return Leaf.creationBlock(leaf);
  }

  function id(uint256 leaf) public pure returns (uint32) {
    return Leaf.id(leaf);
  }
}
