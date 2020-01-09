pragma solidity ^0.5.10;

library Position {

  // Return the last 4 bits of a position number,
  // corresponding to its slot in its parent
  function slot(uint a) public view returns (uint) {
    return a & 0xf;
  }

  // Return the parent of a position number
  function parent(uint a) public view returns (uint) {
    return a >> 4;
  }

  // Return the location of the child of a at the given slot
  function child(uint a, uint s) public view returns (uint) {
    return (a << 4) | slot(s);
  }
}
