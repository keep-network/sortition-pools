pragma solidity ^0.5.10;

import '../../contracts/Operator.sol';

contract OperatorStub {
    function skip(
        uint truncatedIndex,
        uint[] memory previousLeafStartingIndices,
        uint[] memory previousLeafWeights
    )
        public
        pure
        returns (uint mappedIndex)
    {
        uint256 nPreviousLeaves = previousLeafStartingIndices.length;

        uint256[] memory previousLeaves = new uint256[](nPreviousLeaves);

        for (uint256 i = 0; i < nPreviousLeaves; i++) {
            uint256 index = previousLeafStartingIndices[i];
            uint256 weight = previousLeafWeights[i];
            previousLeaves[i] = Operator.make(
                index,
                weight
            );
        }

        return Operator.skip(truncatedIndex, previousLeaves);
    }
}
