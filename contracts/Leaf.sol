pragma solidity ^0.5.10;

import './Branch.sol';
import "solidity-bytes-utils/contracts/BytesLib.sol";

library Leaf {
  using Branch for uint;
  using BytesLib for bytes;

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
    return leaf.toBytes().toAddress(0);
  }

  function weight(uint leaf) internal pure returns (uint) {
    return uint(leaf.toBytes().toUint16(20));
  }
}
