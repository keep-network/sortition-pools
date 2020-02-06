pragma solidity ^0.5.10;

import "./Sortition.sol";
import "./RNG.sol";
import "./api/IStaking.sol";
import "./api/IBonding.sol";

/// @title Bonded Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed and bonding requirements.
contract BondedSortitionPool is Sortition {
    IStaking stakingContract;
    IBonding bondingContract;
    uint256 minimumStake;
    // The pool should specify a reasonable minimum bond
    // for operators trying to join the pool,
    // to prevent griefing by operators joining without enough bondable value.
    // After we start selecting groups
    // this value can be set to equal the most recent request's bondValue.
    uint256 minimumBondableValue;

    // The contract (e.g. Keep factory) this specific pool serves.
    // To prevent griefing,
    // only the pool owner can modify the minimum bondable value.
    // Not required for non-bonded sortition pools.
    address poolOwner;

    constructor(
        IStaking _stakingContract,
        IBonding _bondingContract,
        uint256 _minimumStake,
        uint256 _minimumBondableValue,
        address _poolOwner
    ) public {
        stakingContract = _stakingContract;
        bondingContract = _bondingContract;
        minimumStake = _minimumStake;
        minimumBondableValue = _minimumBondableValue;
        poolOwner = _poolOwner;
    }

    /// @notice Selects a new group of operators of the provided size based on
    /// the provided pseudo-random seed and bonding requirements. All operators
    /// in the group are unique.
    ///
    /// If there are not enough operators in a pool to form a group or not
    /// enough operators are eligible for work selection given the bonding
    /// requirements, the function fails.
    /// @param groupSize Size of the requested group
    /// @param seed Pseudo-random number used to select operators to group
    /// @param bondValue Size of the requested bond per operator
    function selectSetGroup(
        uint256 groupSize,
        bytes32 seed,
        uint256 bondValue
    ) public returns (address[] memory) {
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

    // Return whether the operator is eligible for the pool.
    function isOperatorEligible(address operator) public view returns (bool) {
        return true;
    }

    // Return whether the operator is present in the pool.
    function isOperatorInPool(address operator) public view returns (bool) {
        return true;
    }

    // Return whether the operator's weight in the pool
    // matches their eligible weight.
    function isOperatorUpToDate(address operator) public view returns (bool) {
        return true;
    }

    // Add an operator to the pool,
    // reverting if the operator is already present.
    function joinPool(address operator) public {
        assert(true);
    }

    // Update the operator's weight if present and eligible,
    // or remove from the pool if present and ineligible.
    function updateOperatorStatus(address operator) public {
        assert(true);
    }

    // Return the eligible weight of the operator,
    // which may differ from the weight in the pool.
    // Return 0 if ineligible.
    function getEligibleWeight(address operator) internal view returns (uint256) {
        return 0;
    }

    // Return the weight of the operator in the pool,
    // which may or may not be out of date.
    function getPoolWeight(address operator) internal view returns (uint256) {
        return 0;
    }
}
