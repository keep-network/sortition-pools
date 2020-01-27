pragma solidity ^0.5.10;

/// @notice The implicit 16-ary trees of the sortition pool
/// rely on packing 16 "slots" of 16-bit values into each uint256.
/// The Branch library permits efficient calculations on these slots.
library Branch {

  /// @notice Calculate the right shift required
  /// to make the 16 least significant bits of an uint256
  /// be the bits of the `position`th slot
  /// when treating the uint256 as a uint16[16].
  ///
  /// @dev Not used for efficiency reasons,
  /// but left to illustrate the meaning of a common pattern.
  /// I wish solidity had macros, even C macros.
  function slotShift(uint position) internal pure returns (uint) {
    return (15 - position) * 16;
  }

  /// @notice Return the `position`th slot of the `node`,
  /// treating `node` as a uint16[16].
  function getSlot(uint node, uint position) internal pure returns (uint) {
    uint shiftBits = (15 - position) * 16;
    // Doing a bitwise AND with `0xffff`
    // clears all but the 16 least significant bits.
    // Because of the right shift by `slotShift(position)` bits,
    // those 16 bits contain the 16 bits in the `position`th slot of `node`.
    return (node >> shiftBits) & 0xffff;
  }

  /// @notice Return `node` with the `position`th slot set to zero.
  function clearSlot(uint node, uint position) internal pure returns (uint) {
    uint shiftBits = (15 - position) * 16;
    // Shifting `0xffff` left by `slotShift(position)` bits
    // gives us a number where all bits of the `position`th slot are set,
    // and all other bits are unset.
    //
    // Using a bitwise NOT on this number,
    // we get a uint256 where all bits are set
    // except for those of the `position`th slot.
    //
    // Bitwise ANDing the original `node` with this number
    // sets the bits of `position`th slot to zero,
    // leaving all other bits unchanged.
    return node & ~(0xffff << shiftBits);
  }

  /// @notice Return `node` with the `position`th slot set to `weight`.
  ///
  /// @dev Never call unless `weight` is truncated to 16 bits beforehand,
  /// or the invariant is otherwise guaranteed to hold.
  ///
  /// @param weight The weight of of the node.
  /// ABSOLUTELY REQUIRED to be a 16-bit number;
  /// i.e. with only the 16 least significant bits (potentially) set.
  /// If `weight` exceeds `2^16 - 1`,
  /// the behavior of `setSlot()` becomes ridiculously unsafe
  /// and everything breaks.
  function setSlot(uint node, uint position, uint weight) internal pure returns (uint) {
    uint shiftBits = (15 - position) * 16;
    // Clear the `position`th slot like in `clearSlot()`.
    //
    // Shift `weight` left by `slotShift(position)` bits
    // to obtain a uint256 with all bits unset
    // except in the `position`th slot
    // which contains `weight`.
    //
    // When we bitwise OR these together,
    // all other slots except the `position`th one come from the left argument,
    // and the `position`th gets filled with `weight` from the right argument.
    return node & ~(0xffff << shiftBits) | (weight << shiftBits);
  }

  /// @notice Calculate the summed weight of all slots in the `node`.
  function sumWeight(uint node) internal pure returns (uint) {
    uint sum;

    for (uint i = 0; i < 16; i++) {
      // Iterate through each slot
      // by shifting `node` right in increments of 16 bits,
      // and adding the 16 least significant bits to the `sum`.
      sum += (node >> (i * 16)) & 0xffff;
    }
    return sum;
  }

  /// @notice Pick a slot in `node` that corresponds to `index`.
  /// Treats the node like an array of virtual stakers,
  /// the number of virtual stakers in each slot corresponding to its weight,
  /// and picks which slot contains the `index`th virtual staker.
  ///
  /// @dev Requires that `index` be lower than `sumWeight(node)`.
  /// However, this is not enforced for performance reasons.
  /// If `index` exceeds the permitted range,
  /// `pickWeightedSlot()` returns the rightmost slot
  /// and an excessively high `newIndex`.
  ///
  /// @return slot The slot of `node` containing the `index`th virtual staker.
  ///
  /// @return newIndex The index of the `index`th virtual staker of `node`
  /// within the returned slot.
  function pickWeightedSlot(uint node, uint index)
    internal
    pure
    returns (uint slot, uint newIndex) {

    uint currentSlotWeight;
    newIndex = index;

    for (slot = 0; slot < 16; slot++) {
      currentSlotWeight = (node >> ((15 - slot) * 16)) & 0xffff;

      if (newIndex < currentSlotWeight) {
        break;
      } else {
        newIndex -= currentSlotWeight;
      }
    }

    return (slot, newIndex);
  }
}
