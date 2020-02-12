pragma solidity ^0.5.10;

import '../../contracts/RNG.sol';

contract RNGStub {
    function bitsRequired(uint range) public pure returns (uint) {
        return RNG.bitsRequired(range);
    }

    function truncate(uint bits, uint input) public pure returns (uint) {
        return RNG.truncate(bits, input);
    }

    function getIndex(uint range, uint state) public pure returns (uint) {
        uint i;
        bytes32 s;
        (i, s) = RNG.getIndex(range, bytes32(state));
        return i;
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
