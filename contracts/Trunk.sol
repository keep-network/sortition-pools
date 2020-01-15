pragma solidity ^0.5.10;

library Trunk {
  uint constant trunkSize = 65536;

  // the first leaf of the trunk
  function firstLeaf(uint trunkN) internal pure returns (uint) {
    return trunkSize * trunkN;
  }

  // the last leaf of the trunk
  function lastLeaf(uint trunkN) internal pure returns (uint) {
    return trunkSize * (trunkN + 1) - 1;
  }
}
