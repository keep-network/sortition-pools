pragma solidity 0.8.17;

import "../../contracts/Position.sol";

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
}
