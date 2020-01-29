pragma solidity ^0.5.10;

import "./Sortition.sol";
import "./RNG.sol";

/// @title A third party Bonding Contract providing information to the pool
/// about operator's eligibility for work selection.
interface BondingContract {

    /// @notice Function checks if the provided operator is eligible for work
    /// selection given the bonding requirements.
    ///
    /// The function returns true if the actual staker weight of the operator is
    /// equal or greater than the weight in the argument, and the operator is
    /// eligible for work selection from that pool, and any bond required can
    /// be created.
    ///
    /// The function returning false due to the operator not being eligble for
    /// work selection, the provided weight exceeds its actual staker weight, or
    /// any required bond is not possible to be created.
    ///
    /// Operators for which this function returns false are removed from the
    /// pool and not taken into account for work selection.
    function isEligible(
        address operator,
        uint stakingWeight,
        uint bondSize
    ) external returns (bool);
}


/// @title Bonded Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed and bonding requirements.
contract BondedSortitionPool is Sortition {
    /// @notice Selects a new group of operators of the provided size based on
    /// the provided pseudo-random seed and bonding requirements. All operators
    /// in the group are unique.
    ///
    /// If there are not enough operators in a pool to form a group or not
    /// enough operators are eligible for work selection given the bonding
    /// requirements, the function fails.
    /// @param groupSize Size of the requested group
    /// @param seed Pseudo-random number used to select operators to group
    /// @param bondSize Size of the requested bond per operator
    /// @param bondingContract 3rd party contract checking bond requirements
    function selectSetGroup(
        uint256 groupSize,
        bytes32 seed,
        uint bondSize,
        BondingContract bondingContract
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