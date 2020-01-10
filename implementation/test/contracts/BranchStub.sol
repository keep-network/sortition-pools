pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import '../../contracts/Branch.sol';

contract BranchStub is Branch {
  function publicGetSlot(uint node, uint position) public pure returns (uint) {
    return getSlot(node, position);
  }

  function publicSetSlot(uint node, uint position, uint weight) public pure returns (uint) {
    return setSlot(node, position, weight);
  }

  function publicSumWeight(uint node) public pure returns (uint) {
    return sumWeight(node);
  }
}
