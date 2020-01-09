pragma solidity ^0.5.10;

contract Trunk {
  uint constant trunkSize = 65536;

  // the first leaf of the trunk
  function firstLeaf(uint trunkN) public view returns (uint) {
    return trunkSize * trunkN;
  }

  // the last leaf of the trunk
  function lastLeaf(uint trunkN) public view returns (uint) {
    return trunkSize * (trunkN + 1) - 1;
  }
}
