
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '../../contracts/Interval.sol';
import '../../contracts/DynamicArray.sol';

contract IntervalStub {
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
            previousLeaves[i] = Interval.make(
                index,
                weight
            );
        }

        return Interval.skip(truncatedIndex, DynamicArray.convert(previousLeaves));
    }
}
