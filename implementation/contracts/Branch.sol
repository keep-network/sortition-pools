pragma solidity ^0.5.10;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Branch {
  using BytesLib for bytes;

  function toBytes(uint256 x) internal pure returns (bytes memory) {
    bytes32 b = bytes32(x);
    bytes memory c = new bytes(32);
    for (uint i=0; i < 32; i++) {
      c[i] = b[i];
    }
    return c;
  }

  function slotsToUint(uint16[16] memory slots) internal pure returns (uint) {
    bytes memory b = new bytes(32);

    for (uint i = 0; i < 16; i++) {
      bytes2 s = bytes2(slots[i]);
      uint pos = i*2;

      b[pos] = s[0];
      b[pos + 1] = s[1];
    }
    return b.toUint(0);
  }

  function getSlot(uint node, uint position) internal pure returns (uint16) {
    bytes memory nodeBytes = toBytes(node);
    uint16 theSlot = nodeBytes.toUint16(position * 2);

    return theSlot;
  }

  function setSlot(uint node, uint position, uint16 weight) internal pure returns (uint) {
    uint16[16] memory slots = toSlots(node);

    slots[position] = weight;

    return slotsToUint(slots);
  }

  function toSlots(uint node) internal pure returns (uint16[16] memory) {
    uint16[16] memory slots;

    for (uint i = 0; i < 16; i++) {
      slots[i] = getSlot(node, i);
    }
    return slots;
  }

  function sumWeight(uint node) internal pure returns (uint) {
    uint16[16] memory s = toSlots(node);

    uint sum = 0;

    for (uint i = 0; i < 16; i++) {
      sum += s[i];
    }
    return sum;
  }

  function pickWeightedSlot(uint node, uint initialWeight) internal pure returns (uint, uint) {
    require(initialWeight < sumWeight(node), "Weight too big for this node");
    uint16[16] memory theSlots = toSlots(node);

    bool slotFound = false;
    uint weightRemaining = initialWeight;

    uint currentSlot = 0;

    while (slotFound == false) {
      uint16 currentSlotWeight = getSlot(node, currentSlot);

      if (weightRemaining < currentSlotWeight) {
        slotFound = true;
      } else {
        currentSlot += 1;
        weightRemaining -= currentSlotWeight;
      }
    }

    return (currentSlot, weightRemaining);
  }
}