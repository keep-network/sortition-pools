pragma solidity ^0.5.10;

library RNG {

  // Our sortition pool can support up to 2**19 virtual stakers
  // Therefore we determine how many bits we need from 1 to 19
  function bitsRequired(uint range) internal pure returns (uint) {
    uint bits;
    // Start at 19 to be faster for large ranges
    for (bits = 18; bits >= 0; bits--) {
      // Left shift by `bits`,
      // so we have a 1 in the (bits + 1)th least significant bit
      // and 0 in other bits.
      // If this number is equal or greater than `range`,
      // the range [0, range-1] fits in `bits` bits.
      //
      // Because we loop from high bits to low bits,
      // we find the highest number of bits that doesn't fit the range,
      // and return that number + 1.
      if (1 << bits < range) {
        break;
      }
    }
    return bits + 1;
  }

  // Truncate `input` to `bits` bits.
  function truncate(uint bits, uint input) internal pure returns (uint) {
    return input & ((1 << bits) - 1);
  }

  // Take `range, state`, return `index, state`. The initial state needs to be
  // obtained from trusted randomness oracle (random beacon).
  // Threading the state around is necessary for the PRNG and we do not want
  // to keep the state in the storage to avoid costly updates.
  // `index` is in the range [0, range-1].
  function getIndex(uint range, bytes32 state) internal pure returns (uint, bytes32) {
    uint bits = bitsRequired(range);
    return efficientGetIndex(range, bits, state);
  }

  function efficientGetIndex(uint range, uint bits, bytes32 state) internal pure returns (uint, bytes32) {
    bool found = false;
    uint index;
    while (!found) {
      index = truncate(bits, uint(state));
      state = keccak256(abi.encode(state));
      if (index < range) {
        found = true;
      }
    }
    return (index, state);
  }

  /// @notice Return an index corresponding to a new, unique leaf.
  ///
  /// @dev Gets a new index in a truncated range
  /// with the weights of all previously selected leaves subtracted.
  /// This index is then mapped to the full range of possible indices,
  /// skipping the ranges covered by previous leaves.
  ///
  /// @param range The full range in which the unique index should be.
  ///
  /// @param state The RNG state.
  ///
  /// @param previousLeaves List of indices
  /// corresponding to the _first_ index of each previously selected leaf.
  /// An index number `i` is a starting index of leaf `o`
  /// if querying for index `i` in the sortition pool returns `o`,
  /// but querying for `i-1` returns a different leaf.
  /// This list REALLY needs to be sorted from smallest to largest.
  ///
  /// previousLeafWeights List of weights of previously selected leaves.
  /// This list must be the same length as `previousLeafStartingIndices`
  /// and in the same order.
  ///
  /// @param sumPreviousWeights The sum of the weights of previous leaves.
  /// Could be calculated from `previousLeafWeights`
  /// but providing it explicitly makes the function a bit simpler.
  function getUniqueIndex(
    uint range,
    bytes32 state,
    IndexWeight[] memory previousLeaves,
    uint sumPreviousWeights,
    uint nPreviousLeaves
  ) internal
    pure
    returns (uint uniqueIndex, bytes32 newState)
  {
    // Get an index in the truncated range.
    // The truncated range covers only new leaves,
    // but has to be mapped to the actual range of indices.
    uint truncatedRange = range - sumPreviousWeights;
    uint truncatedIndex;
    /* (truncatedIndex, newState) = getIndex(truncatedRange, state); */

    /* // Map the truncated index to the available unique indices. */
    /* index = internalUniquifyIndex( */
    /*   truncatedIndex, */
    /*   previousLeaves, */
    /*   nPreviousLeaves */
    /* ); */

    (truncatedIndex, newState) = getIndex(truncatedRange, state);
    uniqueIndex = truncatedIndex;

    for (uint i = 0; i < nPreviousLeaves; i++) {
      // If the index is greater than the starting index of the `i`th leaf,
      // we need to skip that leaf.
      if (uniqueIndex >= previousLeaves[i].index) {
        // Add the weight of this previous leaf to the index,
        // ensuring that we skip the leaf.
        uniqueIndex += previousLeaves[i].weight;
      }
    }

    return (uniqueIndex, newState);
  }

  struct IndexWeight {
    uint index;
    uint weight;
  }

  function internalUniquifyIndex(
    uint truncatedIndex,
    IndexWeight[] memory previousLeaves,
    uint nPreviousLeaves
  ) internal
    pure
    returns (uint mappedIndex)
  {
    mappedIndex = truncatedIndex;

    for (uint i = 0; i < nPreviousLeaves; i++) {
      // If the index is greater than the starting index of the `i`th leaf,
      // we need to skip that leaf.
      if (mappedIndex >= previousLeaves[i].index) {
        // Add the weight of this previous leaf to the index,
        // ensuring that we skip the leaf.
        mappedIndex += previousLeaves[i].weight;
      }
    }

    return mappedIndex;
  }

  /// @notice A more easily testable utility function
  /// for turning a truncated index into a unique index.
  function uniquifyIndex(
    uint truncatedIndex,
    uint[] memory previousLeafStartingIndices,
    uint[] memory previousLeafWeights
  ) internal
    pure
    returns (uint mappedIndex)
  {
    // Just a textual convenience
    uint nPreviousLeaves = previousLeafStartingIndices.length;
    // Start by setting the index at the truncated index
    mappedIndex = truncatedIndex;

    for (uint i = 0; i < nPreviousLeaves; i++) {
      // If the index is greater than the starting index of the `i`th leaf,
      // we need to skip that leaf.
      if (mappedIndex >= previousLeafStartingIndices[i]) {
        // Add the weight of this previous leaf to the index,
        // ensuring that we skip the leaf.
        mappedIndex += previousLeafWeights[i];
      }
    }

    return mappedIndex;
  }

  function remapIndices(
    uint deletedStartingIndex,
    uint deletedWeight,
    IndexWeight[] memory previousLeaves
  ) internal
    pure
    returns (IndexWeight[] memory)
  {
    uint nPreviousLeaves = previousLeaves.length;

    for (uint i = 0; i < nPreviousLeaves; i++) {
      // If index is greater than the index of the deleted leaf,
      // reduce the starting index by the weight of the deleted leaf.
      if (previousLeaves[i].index > deletedStartingIndex) {
        previousLeaves[i].index -= deletedWeight;
      }
    }

    return previousLeaves;
  }
}
