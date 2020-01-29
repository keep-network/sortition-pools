pragma solidity ^0.5.10;

import "./Sortition.sol";
import "./RNG.sol";

/// @title Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed.
/// @dev Keeping pool up to date cannot be done eagerly as proliferation of
/// privileged customers could be used to perform DOS attacks by increasing the
/// cost of such updates. When a sortition pool prospectively selects an
/// operator, the selected operator’s eligibility status and weight are checked
/// and, if necessary, updated in the sortition pool. If the changes would be
/// detrimental to the operator, the operator selection is performed again with
/// the updated input to ensure correctness.
contract SortitionPool is Sortition {
    using Leaf for uint;

    /// @notice Selects a new group of operators of the provided size based on
    /// the provided pseudo-random seed. At least one operator has to be
    // registered in the pool, otherwise the function fails reverting the
    /// transaction.
    /// @param groupSize Size of the requested group
    /// @param seed Pseudo-random number used to select operators to group
    function selectGroup(
        uint256 groupSize, bytes32 seed
    ) public view returns (address[] memory)  {
        uint totalWeight = totalWeight();
        require(totalWeight > 0, "No operators in pool");

        address[] memory selected = new address[](groupSize);

        uint idx;
        bytes32 state = seed;

        for (uint i = 0; i < groupSize; i++) {
            (idx, state) = RNG.getIndex(totalWeight, bytes32(state));
            selected[i] = leaves[pickWeightedLeaf(idx)].operator();
        }

        return selected;
    }

    /// @notice Selects a new group of operators of the provided size based on
    /// the provided pseudo-random seed. All operators in the group are unique.
    /// If there are not enough operators in a pool to form a group, the
    /// function fails.
    /// @param groupSize Size of the requested group
    /// @param seed Pseudo-random number used to select operators to group
    function selectSetGroup(
        uint256 groupSize, bytes32 seed
    ) public view returns (address[] memory) {
        require(operatorsInPool() >= groupSize, "Not enough operators in pool");

        address[] memory selected = new address[](groupSize);
        uint selectedWeight = 0;

        //
        // FIXME! THIS IS NOT A SECURE ALGORITHM AND IT HAS TO BE REPLACED!
        // IT IS JUST A TEMPORARY SOLUTION ALLOWING US TO CODE AGAINST
        // THIS INTERFACE.
        //
        for (uint i = 0; i < groupSize; i++) {
            uint leaf = leaves[pickWeightedLeaf(selectedWeight)];
            selected[i] = leaf.operator();
            selectedWeight += leaf.weight();
        }

        return selected;
    }
}