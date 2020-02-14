pragma solidity ^0.5.10;

import "./AbstractSortitionPool.sol";
import "./RNG.sol";
import "./api/IStaking.sol";
import "./api/IBonding.sol";

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
        Uint256x2 memory indexAndRoot = Uint256x2(0, root);
        Uint256x2 memory leafPtrAndStartIndex = Uint256x2(0, 0);
        Uint256x1 memory lastOperator = Uint256x1(0);

        PoolParams memory params = PoolParams(
            staking,
            bonding,
            poolOwner,
            indexAndRoot.b,
            indexAndRoot.b.sumWeight(),
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
        uint256[] memory skippedLeaves = allocateCreate();

        /* loop */
        while (params._selectedCount < groupSize) {
            require(
                params._poolWeight > params._skippedTotalWeight,
                "Not enough operators in pool"
            );

            (indexAndRoot.a, params._rngState) = RNG.getUniqueIndex(
                params._poolWeight,
                params._rngState,
                skippedLeaves,
                params._skippedTotalWeight
            );

            nonAllocatingPick(indexAndRoot, leafPtrAndStartIndex);

            uint256 theLeaf = leaves[leafPtrAndStartIndex.a];
            // Check that the leaf is old enough
            bool mature = theLeaf.creationBlock() + INIT_BLOCKS < block.number;
            address operator = theLeaf.operator();
            uint256 leafWeight = theLeaf.weight();
            bool eligible = queryEligibleWeight(operator, params) >= leafWeight;

            lastOperator.a = Operator.make(
                operator,
                !eligible,
                leafPtrAndStartIndex.a,
                leafPtrAndStartIndex.b,
                leafWeight
            );

            // Good operators go into the group and the list to skip,
            // naughty operators get deleted
            if (!eligible) {
                removeDuringSelection(params, skippedLeaves, lastOperator.a);
                indexAndRoot.b = params._root;
                continue;
            }

            // We insert the new operator into the skipped list,
            // keeping the list ordered by the starting indices.
            lastOperator.a = Operator.insert(
                skippedLeaves,
                lastOperator.a
            );

            // Now the outside element is the last one,
            // so we push it to the end of the list.
            yoloPush(skippedLeaves, lastOperator);

            // And increase the skipped weight,
            params._skippedTotalWeight += leafWeight;

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

    function allocateCreate() internal returns (uint256[] memory) {
        uint256[] memory array;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            array := mload(0x40)
            mstore(array, 0)
            mstore(0x40, add(array, 0x20))
        }
        return array;
    }

    function allocatePush(uint256[] memory array, uint256 item) internal {
        uint256 arrayLastItemPointer;
        uint256 arrayLength = array.length;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            arrayLastItemPointer := add(array, mul(add(arrayLength, 1), 0x20))
        }
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(add(arrayLastItemPointer, 0x20), item)
            mstore(array, add(arrayLength, 1))
            mstore(0x40, add(arrayLastItemPointer, 0x40))
        }
    }
}
