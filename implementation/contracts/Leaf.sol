pragma solidity ^0.5.10;

import './Branch.sol';
import "solidity-bytes-utils/contracts/BytesLib.sol";

contract Leaf is Branch {
  using BytesLib for bytes;

  function makeLeaf(address operator, uint16 weight) public view returns (uint) {
    bytes memory padding = new bytes(10);
    for (uint i=0; i < 10; i++) {
      padding[i] = 0;
    }

    bytes memory addressBytes = new bytes(20);
    bytes20 op = bytes20(operator);
    for (uint i=0; i < 20; i++) {
      addressBytes[i] = op[i];
    }

    bytes memory weightBytes = new bytes(2);
    bytes2 wt = bytes2(weight);
    for (uint i=0; i < 2; i++) {
      weightBytes[i] = wt[i];
    }

    bytes memory contentBytes = addressBytes.concat(weightBytes);
    bytes memory leafBytes = contentBytes.concat(padding);

    return leafBytes.toUint(0);
  }

  function operator(uint leaf) public view returns (address) {
    return toBytes(leaf).toAddress(0);
  }

  function weight(uint leaf) public view returns (uint16) {
    return toBytes(leaf).toUint16(20);
  }
}
