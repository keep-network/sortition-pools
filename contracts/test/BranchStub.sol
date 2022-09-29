pragma solidity 0.8.17;

import "../../contracts/Branch.sol";

contract BranchStub {
  function getSlot(uint node, uint position) public pure returns (uint) {
    return Branch.getSlot(node, position);
  }

  function clearSlot(uint node, uint position) public pure returns (uint) {
    return Branch.clearSlot(node, position);
  }

  function setSlot(uint node, uint position, uint weight) public pure returns (uint) {
    return Branch.setSlot(node, position, weight);
  }

  function sumWeight(uint node) public pure returns (uint) {
    return Branch.sumWeight(node);
  }
}
