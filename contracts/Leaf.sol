pragma solidity ^0.5.10;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Leaf {
  using BytesLib for bytes;

  function toBytes(uint256 x) internal pure returns (bytes memory) {
    bytes32 b = bytes32(x);
    bytes memory c = new bytes(32);
    for (uint i=0; i < 32; i++) {
      c[i] = b[i];
    }
    return c;
  }

  function make(address operator, uint weight) internal pure returns (uint) {
    bytes memory leafBytes = new bytes(32);
    bytes20 op = bytes20(operator);
    bytes2 wt = bytes2(uint16(weight));

    for (uint i=0; i < 20; i++) {
      leafBytes[i] = op[i];
    }

    for (uint j=0; j < 2; j++) {
      leafBytes[j + 20] = wt[j];
    }

    return leafBytes.toUint(0);
  }

  function operator(uint leaf) internal pure returns (address) {
    return toBytes(leaf).toAddress(0);
  }

  function weight(uint leaf) internal pure returns (uint) {
    return uint(toBytes(leaf).toUint16(20));
  }
}
