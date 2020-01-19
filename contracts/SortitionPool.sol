pragma solidity ^0.5.10;

import "./Sortition.sol";
import "./RNG.sol";

contract SortitionPool is Sortition {
    using Leaf for uint;

    function selectGroup(uint256 groupSize, bytes32 seed) public view returns (address[] memory)  {
        uint totalWeight = totalWeight();
        require(totalWeight > 0, "No operators in pool");

        address[] memory selected = new address[](groupSize);

        uint idx;
        bytes32 state = bytes32(seed);

        for (uint i = 0; i < groupSize; i++) {
            (idx, state) = RNG.getIndex(totalWeight, bytes32(state));
            selected[i] = leaves[pickWeightedLeaf(idx)].operator();
        }

        return selected;
    }
}