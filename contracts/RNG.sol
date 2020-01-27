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

  /// @notice Truncate `input` to the `bits` least significant bits.
  function truncate(uint bits, uint input) internal pure returns (uint) {
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
  function getIndex(uint range, bytes32 state)
    internal
    pure
    returns (uint index, bytes32 newState) {
    uint bits = bitsRequired(range);
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
  function efficientGetIndex(uint range, uint bits, bytes32 state)
    internal
    pure
    returns (uint, bytes32)
  {
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
}
