pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import '../../contracts/RNG.sol';

contract RNGStub {
  function bitsRequired(uint range) public returns (uint) {
    return RNG.bitsRequired(range);
  }

  function truncate(uint bits, uint input) public returns (uint) {
    return RNG.truncate(bits, input);
  }

  function getIndex(uint range, uint state) public returns (uint) {
    uint i;
    bytes32 s;
    (i, s) = RNG.getIndex(range, bytes32(state));
    return i;
  }

  function getManyIndices(uint range, uint howMany) public returns (uint) {
    uint i;
    bytes32 s;
    uint sum;
    uint bits = RNG.bitsRequired(range);
    for (uint i = 0; i < howMany; i++) {
      (i, s) =  RNG.efficientGetIndex(range, bits, bytes32(i));
      sum += i;
    }
    return sum;
  }

  function uniquifyIndex(
    uint truncatedIndex,
    uint[] memory previousLeafStartingIndices,
    uint[] memory previousLeafWeights
  ) public
    pure
    returns (uint mappedIndex)
  {
    return RNG.uniquifyIndex(
      truncatedIndex,
      previousLeafStartingIndices,
      previousLeafWeights
    );
  }
}
