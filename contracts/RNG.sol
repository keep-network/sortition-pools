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

  // Take `range, state`, return `index, state`.
  // Threading the state around is necessary for the PRNG.
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
}
