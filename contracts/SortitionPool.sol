pragma solidity ^0.5.10;

import "./Sortition.sol";
import "./RNG.sol";

interface StakingContract {
    function eligibleStake(address operator) external view returns (uint);
}

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
    using Leaf for uint256;
    using Position for uint256;

    uint256 MINIMUM_STAKE;
    StakingContract staking;
    bytes32 rngSeed;

    constructor (StakingContract stakingContract, uint256 minimumStake) public {
        MINIMUM_STAKE = minimumStake;
        staking = stakingContract;
    }

    function reseed(bytes32 seed) public {
        rngSeed = seed;
    }

    /// @notice Selects a new group of operators of the provided size based on
    /// the stored pseudo-random seed.
    /// @dev At least one operator has to be registered in the pool, otherwise
    /// the function fails reverting the transaction.
    /// @param groupSize Size of the requested group
    function selectGroup(uint256 groupSize) public returns (address[] memory)  {
        uint256 poolWeight = totalWeight();
        require(poolWeight > 0, "No operators in pool");

        address[] memory selected = new address[](groupSize);
        uint256 nSelected = 0;

        uint256 idx;
        uint256 leaf;
        address op;
        uint256 wt;

        bytes32 rngState = rngSeed;

        while (nSelected < groupSize) {
            require(poolWeight > 0, "No eligible operators");

            (idx, rngState) = RNG.getIndex(poolWeight, rngState);
            leaf = leaves[pickWeightedLeaf(idx)];
            op = leaf.operator();
            wt = leaf.weight();

            if (getEligibleWeight(op) >= wt) {
                selected[nSelected] = op;
                nSelected += 1;
            } else {
                removeOperator(op);
                poolWeight -= wt;
            }
        }

        rngSeed = rngState;

        return selected;
    }

    function getEligibleWeight(address operator) internal view returns (uint256) {
        uint256 operatorStake = staking.eligibleStake(operator);
        uint256 operatorWeight = operatorStake / MINIMUM_STAKE;

        return operatorWeight;
    }

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

    function joinPool(address operator) public {
        uint256 eligibleWeight = getEligibleWeight(operator);
        require(
            eligibleWeight > 0,
            "Operator not eligible"
        );

        insertOperator(operator, eligibleWeight);
    }

    function updatePoolWeight(address operator) public {
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
}
