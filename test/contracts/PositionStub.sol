pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import '../../contracts/Position.sol';

contract PositionStub {
  function slot(uint a) public pure returns (uint) {
    return Position.slot(a);
  }

  function parent(uint a) public pure returns (uint) {
    return Position.parent(a);
  }

  function child(uint a, uint s) public pure returns (uint) {
    return Position.child(a, s);
  }

  function trunk(uint a) public pure returns (uint) {
    return Position.trunk(a);
  }
}
