pragma solidity ^0.5.10;

import "./Sortition.sol";
import "./RNG.sol";
import "./api/IStaking.sol";

/// @title Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed.
/// @dev Keeping pool up to date cannot be done eagerly as proliferation of
/// privileged customers could be used to perform DOS attacks by increasing the
/// cost of such updates. When a sortition pool prospectively selects an
/// operator, the selected operator’s eligibility status and weight needs to be
/// checked and, if necessary, updated in the sortition pool. If the changes
/// would be detrimental to the operator, the operator selection is performed
/// again with the updated input to ensure correctness.
contract SortitionPool is Sortition {
    using Leaf for uint256;
    using Position for uint256;

    IStaking stakingContract;
    uint256 minimumStake;

    constructor (IStaking _stakingContract, uint256 _minimumStake) public {
        stakingContract = _stakingContract;
        minimumStake = _minimumStake;
    }

    /// @notice Selects a new group of operators of the provided size based on
    /// the provided pseudo-random seed. At least one operator has to be
    /// registered in the pool, otherwise the function fails reverting the
    /// transaction.
    /// @param groupSize Size of the requested group
    /// @param seed Pseudo-random number used to select operators to group
    /// @return selected Members of the selected group
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
        uint256 eligibleWeight = getEligibleWeight(operator);
        require(
            eligibleWeight > 0,
            "Operator not eligible"
        );

        insertOperator(operator, eligibleWeight);
    }

    // Update the operator's weight if present and eligible,
    // or remove from the pool if present and ineligible.
    function updateOperatorStatus(address operator) public {
        uint256 eligibleWeight = getEligibleWeight(operator);
        uint256 inPoolWeight = getPoolWeight(operator);

        require(
            eligibleWeight != inPoolWeight,
            "Operator already up to date"
        );

        if (eligibleWeight == 0) {
            removeOperator(operator);
        } else {
            updateOperator(operator, eligibleWeight);
        }
    }

    // Return the eligible weight of the operator,
    // which may differ from the weight in the pool.
    // Return 0 if ineligible.
    function getEligibleWeight(address operator) internal view returns (uint256) {
        uint256 operatorStake = stakingContract.eligibleStake(operator, address(this));
        uint256 operatorWeight = operatorStake / minimumStake;

        return operatorWeight;
    }

    // Return the weight of the operator in the pool,
    // which may or may not be out of date.
    function getPoolWeight(address operator) internal view returns (uint256) {
        uint256 flaggedLeaf = getFlaggedOperatorLeaf(operator);
        if (flaggedLeaf == 0) {
            return 0;
        } else {
            uint256 leafPosition = flaggedLeaf.unsetFlag();
            uint256 leafWeight = leaves[leafPosition].weight();
            return leafWeight;
        }
    }
}
