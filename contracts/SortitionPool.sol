pragma solidity ^0.5.10;

import "./AbstractSortitionPool.sol";
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
contract SortitionPool is AbstractSortitionPool {
    constructor(
        IStaking _stakingContract,
        uint256 _minimumStake,
        address _poolOwner
    ) public {
        staking = StakingParams(_stakingContract, _minimumStake);
        poolOwner = _poolOwner;
    }

    // Require 10 blocks after joining
    // before the operator can be selected for a group.
    uint256 constant INIT_BLOCKS = 10;

    /// @notice Selects a new group of operators of the provided size based on
    /// the provided pseudo-random seed. At least one operator has to be
    /// registered in the pool, otherwise the function fails reverting the
    /// transaction.
    /// @param groupSize Size of the requested group
    /// @param seed Pseudo-random number used to select operators to group
    /// @return selected Members of the selected group
    function selectGroup(
        uint256 groupSize, bytes32 seed
    ) public returns (address[] memory)  {
        uint256 _root = root;
        bool _rootChanged = false;
        uint256 poolWeight = _root.sumWeight();
        require(poolWeight > 0, "No operators in pool");

        StakingParams memory _staking = staking;
        address _poolOwner = poolOwner;

        address[] memory selected = new address[](groupSize);
        uint256 nSelected = 0;

        uint256 index;
        uint256 leaf;
        address operator;
        uint256 weight;

        bytes32 rngState = seed;

        while (nSelected < groupSize) {
            require(poolWeight > 0, "No eligible operators");

            (index, rngState) = RNG.getIndex(poolWeight, rngState);
            uint256 leafPosition = pickWeightedLeaf(index, _root);
            leaf = leaves[leafPosition];

            // Check that the leaf is old enough
            // FIXME: inefficient, can lead to an infinite loop.
            if (leaf.creationBlock() + INIT_BLOCKS >= block.number) {
                continue;
            }

            operator = leaf.operator();
            weight = leaf.weight();

            if (queryEligibleWeight(operator, _staking, _poolOwner) >= weight) {
                selected[nSelected] = operator;
                nSelected += 1;
            } else {
                _root = removeLeaf(leafPosition, _root);
                removeOperatorLeaf(operator);
                releaseGas(operator);
                poolWeight -= weight;
                _rootChanged = true;
            }
        }

        if (_rootChanged) {
            root = _root;
        }

        return selected;
    }

    // Return the eligible weight of the operator,
    // which may differ from the weight in the pool.
    // Return 0 if ineligible.
    function getEligibleWeight(address operator) internal view returns (uint256) {
        return queryEligibleWeight(operator, staking, poolOwner);
    }

    function queryEligibleWeight(
        address operator,
        StakingParams memory _staking,
        address _poolOwner
    ) internal view returns (uint256) {
        uint256 operatorStake = _staking._contract.eligibleStake(
            operator,
            _poolOwner
        );
        uint256 operatorWeight = operatorStake / _staking._minimum;

        return operatorWeight;
    }
}
