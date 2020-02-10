pragma solidity ^0.5.10;

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
        for (uint j = 0; j < howMany; j++) {
            (i, s) =  RNG.efficientGetIndex(range, bits, bytes32(j));
            sum += i;
        }
        return sum;
    }

    function uniquifyIndex(
        uint truncatedIndex,
        uint[] memory previousLeafStartingIndices,
        uint[] memory previousLeafWeights
    )
        public
        pure
        returns (uint mappedIndex)
    {
        uint256 nPreviousLeaves = previousLeafStartingIndices.length;

        RNG.IndexWeight[] memory previousLeaves = new RNG.IndexWeight[](nPreviousLeaves);

        for (uint256 i = 0; i < nPreviousLeaves; i++) {
            uint256 index = previousLeafStartingIndices[i];
            uint256 weight = previousLeafWeights[i];
            previousLeaves[i] = RNG.IndexWeight(index, weight);
        }

        return RNG.uniquifyIndex(truncatedIndex, previousLeaves, nPreviousLeaves);
    }
}
