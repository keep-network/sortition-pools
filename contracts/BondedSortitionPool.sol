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
        uint256 nSelected = 0;

        RNG.IndexWeight[] memory selectedLeaves = new RNG.IndexWeight[](
            groupSize
        );
        uint256 selectedTotalWeight = 0;

        // XXX: These two variables do way too varied things,
        // but I need all variable slots I can free.
        // Arbitrary names to underline the absurdity.
        uint256 foo;
        uint256 bar;

        bytes32 rngState = seed;

        uint256 poolWeight = root.sumWeight();

        /* loop */
        while (nSelected < groupSize) {
            require(
                poolWeight > selectedTotalWeight,
                "Not enough operators in pool"
            );

            // uint256 bar;
            // BAR is the UNIQUE INDEX
            (bar, rngState) = RNG.getUniqueIndex(
                poolWeight,
                rngState,
                selectedLeaves,
                selectedTotalWeight,
                nSelected
            );

            // uint256 foo;
            // BAR starts as the UNIQUE INDEX here
            (foo, bar) = pickWeightedLeafWithIndex(bar);
            // FOO is now the POSITION OF THE LEAF
            // BAR is now the STARTING INDEX of the leaf

            // FOO starts as the POSITION OF THE LEAF here
            foo = leaves[foo];
            // FOO is now the LEAF itself
            address operator = foo.operator();
            foo = foo.weight();
            // FOO is now the WEIGHT OF THE OPERATOR

            // Good operators go into the group and the list to skip,
            // naughty operators get deleted
            // FOO is the WEIGHT OF THE OPERATOR here
            if (bondingContract.availableUnbondedValue(operator, poolOwner, address(this)) >= foo * minimumBondableValue) {
                // We insert the new index and weight into the lists,
                // keeping them both ordered by the starting indices.
                // To do this, we start by holding the new element outside the list.

                // BAR is the STARTING INDEX of the leaf
                // FOO is the WEIGHT of the operator
                RNG.IndexWeight memory tempIW = RNG.IndexWeight(bar, foo);

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
                // by FOO which is the WEIGHT of the operator
                selectedTotalWeight += foo;

                selected[nSelected] = operator;
                nSelected += 1;
            } else {
                removeOperator(operator);
                // subtract FOO which is the WEIGHT of the operator
                // from the pool weight
                poolWeight -= foo;

                selectedLeaves = RNG.remapIndices(bar, foo, selectedLeaves);
            }
        }
        /* pool */

        // If nothing has exploded by now,
        // we should have the correct size of group.

        return selected;
    }

    // Return whether the operator is eligible for the pool.
    function isOperatorEligible(address operator) public view returns (bool) {
        return true;
    }

    // Return whether the operator is present in the pool.
    function isOperatorInPool(address operator) public view returns (bool) {
        return isOperatorRegistered(operator);
    }

    // Return whether the operator's weight in the pool
    // matches their eligible weight.
    function isOperatorUpToDate(address operator) public view returns (bool) {
        return true;
    }

    // Add an operator to the pool,
    // reverting if the operator is already present.
    function joinPool(address operator) public {
        // TODO: Implement, this is just a stub.
        uint256 eligibleWeight = bondingContract.availableUnbondedValue(
            operator,
            poolOwner,
            address(this)
        ) / minimumBondableValue;

        insertOperator(operator, eligibleWeight);
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
