pragma solidity ^0.5.10;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Branch {
    using BytesLib for bytes;

    function slotShift(uint256 position) internal pure returns (uint256) {
        return (15 - position) * 16;
    }

    function toBytes(uint256 x) internal pure returns (bytes memory) {
        bytes32 b = bytes32(x);
        bytes memory c = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            c[i] = b[i];
        }
        return c;
    }

    function slotsToUint(uint256[16] memory slots)
        internal
        pure
        returns (uint256)
    {
        uint256 u;

        for (uint256 i = 0; i < 16; i++) {
            u = (u << 16) | (slots[i] & 0xffff);
        }
        return u;
    }

    function getSlot(uint256 node, uint256 position)
        internal
        pure
        returns (uint256)
    {
        uint256 shiftBits = (15 - position) * 16;
        return (node >> shiftBits) & 0xffff;
    }

    function clearSlot(uint256 node, uint256 position)
        internal
        pure
        returns (uint256)
    {
        uint256 shiftBits = (15 - position) * 16;
        return node & ~(0xffff << shiftBits);
    }

    function setSlot(uint256 node, uint256 position, uint256 weight)
        internal
        pure
        returns (uint256)
    {
        uint256 shiftBits = (15 - position) * 16;
        return (node & ~(0xffff << shiftBits)) | (weight << shiftBits);
    }

    function toSlots(uint256 node) internal pure returns (uint256[16] memory) {
        uint256[16] memory slots;

        for (uint256 i = 0; i < 16; i++) {
            slots[i] = getSlot(node, i);
        }
        return slots;
    }

    function sumWeight(uint256 node) internal pure returns (uint256) {
        uint256 sum;

        for (uint256 i = 0; i < 16; i++) {
            sum += (node >> (i * 16)) & 0xffff;
        }
        return sum;
    }

    // Requires that the weight is lower than the sumWeight of the node.
    // This is not enforced for performance reasons.
    function pickWeightedSlot(uint256 node, uint256 weight)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 currentSlotWeight;
        uint256 currentSlot;
        uint256 pickedWeight = weight;

        for (currentSlot = 0; currentSlot < 16; currentSlot++) {
            /* uint shiftBits = ((15 - currentSlot) * 16); */
            currentSlotWeight = (node >> ((15 - currentSlot) * 16)) & 0xffff;

            if (pickedWeight < currentSlotWeight) {
                break;
            } else {
                pickedWeight -= currentSlotWeight;
            }
        }

        return (currentSlot, pickedWeight);
    }
}
