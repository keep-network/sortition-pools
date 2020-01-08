pragma solidity ^0.5.10;

import "BytesLib.sol";

library Branch {
  using BytesLib for bytes;

  function getSlot(uint node, uint position) public view returns (uint16) {
    nodeBytes = bytes(node);

    theSlot = toUint16(nodeBytes.slice(position * 2, 2));

    return theSlot;
  }

  function setSlot(uint node, uint position, uint16 weight) public view returns (uint) {
    
  }

  function toSlots(uint node) public view returns (uint16[16]) {
    uint16[16] memory slots;

    for (uint i = 0; i < 16; i++) {
      slots[i] = getSlot(node, i);
    }

    return slots;
  }

  function sumWeight(uint node) public view returns (uint16) {
    
  }

  function rootWeight(uint root) public view returns (uint) {
    
  }
  
}
