pragma solidity ^0.5.10;

import "./AbstractSortitionPool.sol";
import "./RNG.sol";
import "./api/IStaking.sol";
import "./api/IBonding.sol";

/// @title Bonded Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed and bonding requirements.
contract BondedSortitionPool is AbstractSortitionPool {
    // The pool should specify a reasonable minimum bond
    // for operators trying to join the pool,
    // to prevent griefing by operators joining without enough bondable value.
    // After we start selecting groups
    // this value can be set to equal the most recent request's bondValue.
    struct BondingParams {
        IBonding _contract;
        uint256 _minimumAvailableValue;
    }

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
        bonding._minimumAvailableValue = bondValue;

        require(operatorsInPool() >= groupSize, "Not enough operators in pool");

        SelectedMembers memory selected = SelectedMembers(
            new address[](groupSize),
            0
        );

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
        while (selected.number < groupSize) {
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
                selected.number
            );

            // REGISTER_B starts as the UNIQUE INDEX here
            (registerA, registerB) = pickWeightedLeafWithIndex(registerB);
            // REGISTER_A is now the POSITION OF THE LEAF
            // REGISTER_B is now the STARTING INDEX of the leaf

            uint256 theLeaf;
            // REGISTER_A starts as the POSITION OF THE LEAF here
            theLeaf = leaves[registerA];
            // REGISTER_A is now the LEAF itself
            address operator = theLeaf.operator();
            // REGISTER_A is now the WEIGHT OF THE OPERATOR

            RNG.IndexWeight memory selectedIW = RNG.IndexWeight(
                registerB,
                theLeaf.weight()
            );

            // Good operators go into the group and the list to skip,
            // naughty operators get deleted
            // REGISTER_A is the WEIGHT OF THE OPERATOR here
            if (getEligibleWeight(operator) >= selectedIW.weight) {
                // We insert the new index and weight into the lists,
                // keeping them both ordered by the starting indices.
                // To do this, we start by holding the new element outside the list.

                // REGISTER_B is the STARTING INDEX of the leaf
                // REGISTER_A is the WEIGHT of the operator
                RNG.IndexWeight memory tempIW = selectedIW;

                for (uint256 i = 0; i < selected.number; i++) {
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
                selectedLeaves[selected.number] = tempIW;

                // And increase the skipped weight,
                // by REGISTER_A which is the WEIGHT of the operator
                selectedTotalWeight += selectedIW.weight;

                selected.addresses[selected.number] = operator;
                selected.number += 1;
            } else {
                removeOperator(operator);
                // subtract REGISTER_A which is the WEIGHT of the operator
                // from the pool weight
                poolWeight -= selectedIW.weight;

                selectedLeaves = RNG.remapIndices(
                    selectedIW.index,
                    selectedIW.weight,
                    selectedLeaves
                );
            }
        }
        /* pool */

        // If nothing has exploded by now,
        // we should have the correct size of group.

        return selected.addresses;
    }

    // Return the eligible weight of the operator,
    // which may differ from the weight in the pool.
    // Return 0 if ineligible.
    function getEligibleWeight(address operator) internal view returns (uint256) {
        // Get the amount of bondable value available for this pool.
        // We only care that this covers one single bond
        // regardless of the weight of the operator in the pool.
        uint256 bondableValue = bonding._contract.availableUnbondedValue(
            operator,
            poolOwner,
            address(this)
        );

        // Don't query stake if bond is insufficient.
        if (bondableValue < bonding._minimumAvailableValue) {
            return 0;
        }

        uint256 eligibleStake = staking._contract.eligibleStake(
            operator,
            poolOwner
        );

        // Weight = floor(eligibleStake / mimimumStake)
        // Ethereum uint256 division performs implicit floor
        // If eligibleStake < minimumStake, return 0 = ineligible.
        return eligibleStake / staking._minimum;
    }
}
