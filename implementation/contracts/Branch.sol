pragma solidity ^0.5.10;

import "BytesLib.sol";

library Branch {
  using BytesLib for bytes;

  function getSlot(uint node, uint position) public view returns (uint16) {
    
  }

  function setSlot(uint node, uint position, uint16 weight) public view returns (uint) {
    
  }

  function toSlots(uint node) public view returns (uint16[16]) {
    uint16[16] memory slots;

    nodeBytes = bytes(node)

    for (uint i = 0; i < 16; i++) {
      slots[i] = toUint16(nodeBytes.slice(i * 2, 2));
    }

    return slots;
  }

  function sumWeight(uint node) public view returns (uint16) {
    
  }

  function rootWeight(uint root) public view returns (uint) {
    
  }
  
}
