pragma solidity ^0.5.10;

import "./SortitionTree.sol";
import "./RNG.sol";
import "./api/IStaking.sol";
import "./api/IBonding.sol";

/// @title Bonded Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed and bonding requirements.
contract BondedSortitionPool is SortitionTree {
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
    // only the pool owner can request groups
    // or modify the minimum bondable value.
    address poolOwner;

    constructor(
        IStaking _stakingContract,
        IBonding _bondingContract,
        uint256 _minimumStake,
        uint256 _minimumBondableValue,
        address _poolOwner
    ) public {
        require(_minimumStake > 0, "Minimum stake cannot be zero");

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
        minimumBondableValue = bondValue;

        require(operatorsInPool() >= groupSize, "Not enough operators in pool");

        address[] memory selected = new address[](groupSize);
        uint256 nSelected = 0;

        RNG.IndexWeight[] memory selectedLeaves = new RNG.IndexWeight[](
            groupSize
        );
        uint256 selectedTotalWeight = 0;

        // XXX: These two variables do way too varied things,
        // but I need all variable slots I can free.
        // Arbitrary names to underline the absurdity.
        uint256 registerA;
        uint256 registerB;

        bytes32 rngState = seed;

        uint256 poolWeight = root.sumWeight();

        /* loop */
        while (nSelected < groupSize) {
            require(
                poolWeight > selectedTotalWeight,
                "Not enough operators in pool"
            );

            // REGISTER_B is the UNIQUE INDEX
            (registerB, rngState) = RNG.getUniqueIndex(
                poolWeight,
                rngState,
                selectedLeaves,
                selectedTotalWeight,
                nSelected
            );

            // REGISTER_B starts as the UNIQUE INDEX here
            (registerA, registerB) = pickWeightedLeafWithIndex(registerB);
            // REGISTER_A is now the POSITION OF THE LEAF
            // REGISTER_B is now the STARTING INDEX of the leaf

            // REGISTER_A starts as the POSITION OF THE LEAF here
            registerA = leaves[registerA];
            // REGISTER_A is now the LEAF itself
            address operator = registerA.operator();
            registerA = registerA.weight();
            // REGISTER_A is now the WEIGHT OF THE OPERATOR

            // Good operators go into the group and the list to skip,
            // naughty operators get deleted
            // REGISTER_A is the WEIGHT OF THE OPERATOR here
            if (getEligibleWeight(operator) >= registerA) {
                // We insert the new index and weight into the lists,
                // keeping them both ordered by the starting indices.
                // To do this, we start by holding the new element outside the list.

                // REGISTER_B is the STARTING INDEX of the leaf
                // REGISTER_A is the WEIGHT of the operator
                RNG.IndexWeight memory tempIW = RNG.IndexWeight(registerB, registerA);

                for (uint256 i = 0; i < nSelected; i++) {
                    RNG.IndexWeight memory thisIW = selectedLeaves[i];
                    // With each element of the list,
                    // we check if the outside element should go before it.
                    // If true, we swap that element and the outside element.
                    if (tempIW.index < thisIW.index) {
                        selectedLeaves[i] = tempIW;
                        tempIW = thisIW;
                    }
                }

                // Now the outside element is the last one,
                // so we push it to the end of the list.
                selectedLeaves[nSelected] = tempIW;

                // And increase the skipped weight,
                // by REGISTER_A which is the WEIGHT of the operator
                selectedTotalWeight += registerA;

                selected[nSelected] = operator;
                nSelected += 1;
            } else {
                removeOperator(operator);
                // subtract REGISTER_A which is the WEIGHT of the operator
                // from the pool weight
                poolWeight -= registerA;

                selectedLeaves = RNG.remapIndices(registerB, registerA, selectedLeaves);
            }
        }
        /* pool */

        // If nothing has exploded by now,
        // we should have the correct size of group.

        return selected;
    }

    // Return whether the operator is eligible for the pool.
    function isOperatorEligible(address operator) public view returns (bool) {
        return (getEligibleWeight(operator) > 0);
    }

    // Return whether the operator is present in the pool.
    function isOperatorInPool(address operator) public view returns (bool) {
        return isOperatorRegistered(operator);
    }

    // Return whether the operator's weight in the pool
    // matches their eligible weight.
    function isOperatorUpToDate(address operator) public view returns (bool) {
        return getPoolWeight(operator) == getEligibleWeight(operator);
    }

    // Return the weight of the operator in the pool,
    // which may or may not be out of date.
    function getPoolWeight(address operator) public view returns (uint256) {
        uint256 flaggedLeaf = getFlaggedOperatorLeaf(operator);
        // Not in pool -> has weight 0
        if (flaggedLeaf == 0) {
            return 0;
        } else {
            return leaves[flaggedLeaf.unsetFlag()].weight();
        }
    }

    // Add an operator to the pool,
    // reverting if the operator is already present.
    function joinPool(address operator) public {
        uint256 eligibleWeight = getEligibleWeight(operator);

        require(eligibleWeight > 0, "Operator ineligible");

        insertOperator(operator, eligibleWeight);
    }

    // Update the operator's weight if present and eligible,
    // or remove from the pool if present and ineligible.
    function updateOperatorStatus(address operator) public {
        uint256 poolWeight = getPoolWeight(operator);
        require(poolWeight > 0, "Operator not in pool");

        uint256 eligibleWeight = getEligibleWeight(operator);

        if (eligibleWeight > 0) {
            updateOperator(operator, eligibleWeight);
        } else {
            removeOperator(operator);
        }
    }

    // Return the eligible weight of the operator,
    // which may differ from the weight in the pool.
    // Return 0 if ineligible.
    function getEligibleWeight(address operator) internal view returns (uint256) {
        // Get the amount of bondable value available for this pool.
        // We only care that this covers one single bond
        // regardless of the weight of the operator in the pool.
        uint256 bondableValue = bondingContract.availableUnbondedValue(
            operator,
            poolOwner,
            address(this)
        );

        // Don't query stake if bond is insufficient.
        if (bondableValue < minimumBondableValue) {
            return 0;
        }

        uint256 eligibleStake = stakingContract.eligibleStake(
            operator,
            poolOwner
        );

        // Weight = floor(eligibleStake / mimimumStake)
        // Ethereum uint256 division performs implicit floor
        // If eligibleStake < minimumStake, return 0 = ineligible.
        return eligibleStake / minimumStake;
    }
}
