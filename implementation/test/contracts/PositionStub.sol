pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import '../../contracts/Position.sol';

contract PositionStub is Position {
  function publicSlot(uint a) public pure returns (uint) {
    return slot(a);
  }

  function publicParent(uint a) public pure returns (uint) {
    return parent(a);
  }

  function publicChild(uint a, uint s) public pure returns (uint) {
    return child(a, s);
  }

  function publicTrunk(uint a) public pure returns (uint) {
    return trunk(a);
  }
}
