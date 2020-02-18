pragma solidity ^0.5.10;

import "./AbstractSortitionPool.sol";
import "./RNG.sol";
import "./api/IStaking.sol";
import "./api/IBonding.sol";
import "./DynamicArray.sol";
import "./Heap.sol";

/// @title Bonded Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed and bonding requirements.
/// @dev Keeping pool up to date cannot be done eagerly as proliferation of
/// privileged customers could be used to perform DOS attacks by increasing the
/// cost of such updates. When a sortition pool prospectively selects an
/// operator, the selected operator’s eligibility status and weight needs to be
/// checked and, if necessary, updated in the sortition pool. If the changes
/// would be detrimental to the operator, the operator selection is performed
/// again with the updated input to ensure correctness.
contract BondedSortitionPool is AbstractSortitionPool {
    using DynamicArray for DynamicArray.Array;
    // The pool should specify a reasonable minimum bond
    // for operators trying to join the pool,
    // to prevent griefing by operators joining without enough bondable value.
    // After we start selecting groups
    // this value can be set to equal the most recent request's bondValue.
    struct BondingParams {
        IBonding _contract;
        uint256 _minimumBondableValue;
    }

    struct PoolParams {
        StakingParams _staking;
        BondingParams _bonding;
        address _poolOwner;
        uint256 _root;
        uint256 _poolWeight;
        bool _rootChanged;
        uint256 _skippedTotalWeight;
        uint256 _selectedCount;
        bytes32 _rngState;
    }

    // Require 10 blocks after joining
    // before the operator can be selected for a group.
    uint256 constant INIT_BLOCKS = 10;

    BondingParams bonding;

    constructor(
        IStaking _stakingContract,
        IBonding _bondingContract,
        uint256 _minimumStake,
        uint256 _minimumBondableValue,
        address _poolOwner
    ) public {
        require(_minimumStake > 0, "Minimum stake cannot be zero");

        staking = StakingParams(_stakingContract, _minimumStake);
        bonding = BondingParams(_bondingContract, _minimumBondableValue);
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
        Heap.Uint256x2 memory indexAndRoot = Heap.Uint256x2(0, root);
        Heap.Uint256x2 memory leafPtrAndStartIndex = Heap.Uint256x2(0, 0);

        PoolParams memory params = PoolParams(
            staking,
            bonding,
            poolOwner,
            indexAndRoot.snd,
            indexAndRoot.snd.sumWeight(),
            false,
            0,
            0,
            seed
        );

        if (params._bonding._minimumBondableValue != bondValue) {
            params._bonding._minimumBondableValue = bondValue;
            bonding._minimumBondableValue = bondValue;
        }

        address[] memory selected = new address[](groupSize);

        // uint256[] memory skippedLeaves = new uint256[]();
        DynamicArray.Array memory skippedLeaves = DynamicArray.createArray(groupSize);

        /* loop */
        while (params._selectedCount < groupSize) {
            require(
                params._poolWeight > params._skippedTotalWeight,
                "Not enough operators in pool"
            );

            (indexAndRoot.fst, params._rngState) = RNG.getUniqueIndex(
                params._poolWeight,
                params._rngState,
                skippedLeaves.array,
                params._skippedTotalWeight
            );

            nonAllocatingPick(indexAndRoot, leafPtrAndStartIndex);

            uint256 theLeaf = leaves[leafPtrAndStartIndex.fst];
            // Check that the leaf is old enough
            bool mature = theLeaf.creationBlock() + INIT_BLOCKS < block.number;
            address operator = theLeaf.operator();
            uint256 leafWeight = theLeaf.weight();
            // Only query the up-to-dateness of mature operators,
            // to reduce the cost of dealing with immature ones.
            bool outOfDate = mature &&
                (queryEligibleWeight(operator, params) < leafWeight);

            uint256 lastOperator = Operator.make(
                operator,
                outOfDate,
                leafPtrAndStartIndex.fst,
                leafPtrAndStartIndex.snd,
                leafWeight
            );

            // Remove the operator and get next one if out of date,
            // otherwise add it to the list of operators to skip.
            if (outOfDate) {
                removeDuringSelection(params, skippedLeaves.array, lastOperator);
                indexAndRoot.snd = params._root;
                continue;
            }

            // We insert the new operator into the skipped list,
            // keeping the list ordered by the starting indices.
            lastOperator = Operator.insert(
                skippedLeaves.array,
                lastOperator
            );

            // Now the outside element is the last one,
            // so we push it to the end of the list.
            skippedLeaves.push(lastOperator);

            // And increase the skipped weight,
            params._skippedTotalWeight += leafWeight;

            // If we didn't short-circuit out,
            // the operator is not out of date.
            // This means that checking whether it is `mature` is enough.
            if (mature) {
                selected[params._selectedCount] = operator;
                params._selectedCount += 1;
            }
        }
        /* pool */

        if (params._rootChanged) {
            root = params._root;
        }

        // If nothing has exploded by now,
        // we should have the correct size of group.

        return selected;
    }

    function removeDuringSelection(
        PoolParams memory params,
        uint256[] memory skippedLeaves,
        uint256 operatorData
    ) internal {
        // Remove the leaf
        uint256 leafPosition = Operator.position(operatorData);
        params._root = removeLeaf(leafPosition, params._root);
        // Remove the record of the operator's leaf and release gas
        address operator = Operator.opAddress(operatorData);
        removeOperatorLeaf(operator);
        releaseGas(operator);
        // Update the params
        uint256 weight = Operator.opWeight(operatorData);
        params._poolWeight -= weight;
        params._rootChanged = true;
        // Remap the skipped indices
        uint256 startingIndex = Operator.index(operatorData);
        Operator.remapIndices(startingIndex, weight, skippedLeaves);
    }

    // Return the eligible weight of the operator,
    // which may differ from the weight in the pool.
    // Return 0 if ineligible.
    function getEligibleWeight(address operator) internal view returns (uint256) {
        PoolParams memory params = PoolParams(
            staking,
            bonding,
            poolOwner,
            0,
            0, // the pool weight doesn't matter here
            false,
            0,
            0,
            bytes32(0)
        );
        return queryEligibleWeight(operator, params);
    }

    function queryEligibleWeight(
        address operator,
        PoolParams memory params
    ) internal view returns (uint256) {
        address ownerAddress = params._poolOwner;

        // Get the amount of bondable value available for this pool.
        // We only care that this covers one single bond
        // regardless of the weight of the operator in the pool.
        uint256 bondableValue = params._bonding._contract.availableUnbondedValue(
            operator,
            ownerAddress,
            address(this)
        );

        // Don't query stake if bond is insufficient.
        if (bondableValue < params._bonding._minimumBondableValue) {
            return 0;
        }

        uint256 eligibleStake = params._staking._contract.eligibleStake(
            operator,
            ownerAddress
        );

        // Weight = floor(eligibleStake / mimimumStake)
        // Ethereum uint256 division performs implicit floor
        // If eligibleStake < minimumStake, return 0 = ineligible.
        return (eligibleStake / params._staking._minimum);
    }
}
