pragma solidity ^0.5.10;

library RNG {
    /// @notice Calculate how many bits are required
    /// for an index in the range `[0 .. range-1]`.
    ///
    /// @dev Our sortition pool can support up to 2^19 virtual stakers,
    /// therefore we calculate how many bits we need from 1 to 19.
    ///
    /// @param range The upper bound of the desired range, exclusive.
    ///
    /// @return uint The smallest number of bits
    /// that can contain the number `range-1`.
    function bitsRequired(uint256 range) internal pure returns (uint256) {
        uint256 bits;
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

    /// @notice Truncate `input` to the `bits` least significant bits.
    function truncate(uint256 bits, uint256 input)
        internal
        pure
        returns (uint256)
    {
        return input & ((1 << bits) - 1);
    }

    /// @notice Get an index in the range `[0 .. range-1]`
    /// and the new state of the RNG,
    /// using the provided `state` of the RNG.
    ///
    /// @param range The upper bound of the index, exclusive.
    ///
    /// @param state The previous state of the RNG.
    /// The initial state needs to be obtained
    /// from a trusted randomness oracle (the random beacon),
    /// or from a chain of earlier calls to `RNG.getIndex()`
    /// on an originally trusted seed.
    ///
    /// @dev Calculates the number of bits required for the desired range,
    /// takes the least significant bits of `state`
    /// and checks if the obtained index is within the desired range.
    /// The original state is hashed with `keccak256` to get a new state.
    /// If the index is outside the range,
    /// the function retries until it gets a suitable index.
    ///
    /// @return index A random integer between `0` and `range - 1`, inclusive.
    ///
    /// @return newState The new state of the RNG.
    /// When `getIndex()` is called one or more times,
    /// care must be taken to always use the output `state`
    /// of the most recent call as the input `state` of a subsequent call.
    /// At the end of a transaction calling `RNG.getIndex()`,
    /// the previous stored state must be overwritten with the latest output.
    function getIndex(uint256 range, bytes32 state)
        internal
        pure
        returns (uint256, bytes32)
    {
        uint256 bits = bitsRequired(range);
        return efficientGetIndex(range, bits, state);
    }

    /// @notice Like `getIndex()`,
    /// returns an index in the range `[0 .. range-1]`
    /// using the provided `state` of the RNG.
    /// However, `efficientGetIndex()` doesn't calculate
    /// the number of `bits` required for the range,
    /// but instead relies on the `bits` input parameter
    /// which is assumed to be correctly precalculated.
    ///
    /// @dev Unsafe if not used correctly,
    /// but exposed for potential efficiency gains when the range is constant.
    ///
    /// @param bits The number of bits to use;
    /// assumed to be the lowest number of bits required for the desired range
    /// as would be returned by `bitsRequired(range)`.
    /// If `bits` is less than the output of `bitsRequired(range)`,
    /// the returned index is heavily biased.
    /// If `bits` exceeds the correct value,
    /// efficiency is severely compromised.
    function efficientGetIndex(uint256 range, uint256 bits, bytes32 state)
        internal
        pure
        returns (uint256, bytes32)
    {
        bool found = false;
        uint256 index;
        bytes32 newState = state;

        while (!found) {
            index = truncate(bits, uint256(newState));
            newState = keccak256(abi.encode(newState));
            if (index < range) {
                found = true;
            }
        }
        return (index, newState);
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
    /// @param previousLeafStartingIndices List of indices
    /// corresponding to the _first_ index of each previously selected leaf.
    /// An index number `i` is a starting index of leaf `o`
    /// if querying for index `i` in the sortition pool returns `o`,
    /// but querying for `i-1` returns a different leaf.
    /// This list REALLY needs to be sorted from smallest to largest.
    ///
    /// @param previousLeafWeights List of weights of previously selected leaves.
    /// This list must be the same length as `previousLeafStartingIndices`
    /// and in the same order.
    ///
    /// @param sumPreviousWeights The sum of the weights of previous leaves.
    /// Could be calculated from `previousLeafWeights`
    /// but providing it explicitly makes the function a bit simpler.
    function getUniqueIndex(
        uint256 range,
        bytes32 state,
        uint256[] memory previousLeafStartingIndices,
        uint256[] memory previousLeafWeights,
        uint256 sumPreviousWeights
    ) internal pure returns (uint256 index, bytes32 newState) {
        // Get an index in the truncated range.
        // The truncated range covers only new leaves,
        // but has to be mapped to the actual range of indices.
        uint256 truncatedRange = range - sumPreviousWeights;
        uint256 truncatedIndex;
        (truncatedIndex, newState) = getIndex(truncatedRange, state);

        // Map the truncated index to the available unique indices.
        index = uniquifyIndex(
            truncatedIndex,
            previousLeafStartingIndices,
            previousLeafWeights
        );

        return (index, newState);
    }

    /// @notice A more easily testable utility function
    /// for turning a truncated index into a unique index.
    function uniquifyIndex(
        uint256 truncatedIndex,
        uint256[] memory previousLeafStartingIndices,
        uint256[] memory previousLeafWeights
    ) internal pure returns (uint256 mappedIndex) {
        // Just a textual convenience
        uint256 nPreviousLeaves = previousLeafStartingIndices.length;
        // Start by setting the index at the truncated index
        mappedIndex = truncatedIndex;

        for (uint256 i = 0; i < nPreviousLeaves; i++) {
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
}
