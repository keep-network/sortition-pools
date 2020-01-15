pragma solidity ^0.5.10;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Branch {
  using BytesLib for bytes;

  function slotShift(uint position) internal pure returns (uint) {
    return (15 - position) * 16;
  }

  function toBytes(uint256 x) internal pure returns (bytes memory) {
    bytes32 b = bytes32(x);
    bytes memory c = new bytes(32);
    for (uint i=0; i < 32; i++) {
      c[i] = b[i];
    }
    return c;
  }

  function slotsToUint(uint[16] memory slots) internal pure returns (uint) {
    uint u;

    for (uint i = 0; i < 16; i++) {
      u = (u << 16) | (slots[i] & 0xffff);
    }
    return u;
  }

  function getSlot(uint node, uint position) internal pure returns (uint) {
    uint shiftBits = (15 - position) * 16;
    return (node >> shiftBits) & 0xffff;
  }

  function clearSlot(uint node, uint position) internal pure returns (uint) {
    uint shiftBits = (15 - position) * 16;
    return node & ~(0xffff << shiftBits);
  }

  function setSlot(uint node, uint position, uint weight) internal pure returns (uint) {
    uint shiftBits = (15 - position) * 16;
    return node & ~(0xffff << shiftBits) | (weight << shiftBits);
  }

  function toSlots(uint node) internal pure returns (uint[16] memory) {
    uint[16] memory slots;

    for (uint i = 0; i < 16; i++) {
      slots[i] = getSlot(node, i);
    }
    return slots;
  }

  function sumWeight(uint node) internal pure returns (uint) {
    uint sum;

    for (uint i = 0; i < 16; i++) {
      sum += (node >> (i * 16)) & 0xffff;
    }
    return sum;
  }

  // Requires that the weight is lower than the sumWeight of the node.
  // This is not enforced for performance reasons.
  function pickWeightedSlot(uint node, uint weight) internal pure returns (uint, uint) {

    uint currentSlotWeight;
    uint currentSlot;

    for (currentSlot = 0; currentSlot < 16; currentSlot++) {
      /* uint shiftBits = ((15 - currentSlot) * 16); */
      currentSlotWeight = (node >> ((15 - currentSlot) * 16)) & 0xffff;

      if (weight < currentSlotWeight) {
        break;
      } else {
        weight -= currentSlotWeight;
      }
    }

    return (currentSlot, weight);
  }
}
