pragma solidity ^0.5.10;

library Position {

  // Return the last 4 bits of a position number,
  // corresponding to its slot in its parent
  function slot(uint a) internal pure returns (uint) {
    return a & 0xf;
  }

  // Return the parent of a position number
  function parent(uint a) internal pure returns (uint) {
    return a >> 4;
  }

  // Return the location of the child of a at the given slot
  function child(uint a, uint s) internal pure returns (uint) {
    return (a << 4) | slot(s);
  }

  // Return the trunk a leaf's position belongs to
  function trunk(uint a) internal pure returns(uint) {
    return slot(a >> 16);
  }
}
