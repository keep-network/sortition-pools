pragma solidity ^0.5.10;

import "./GasStation.sol";
import "./RNG.sol";
import "./SortitionTree.sol";
import "./api/IStaking.sol";

/// @title Abstract Sortition Pool
/// @notice Abstract contract encapsulating common logic of all sortition pools.
/// @dev Inheriting implementations are expected to implement getEligibleWeight
/// function.
contract AbstractSortitionPool is SortitionTree, GasStation {
    using Leaf for uint256;
    using Position for uint256;

    struct StakingParams {
        IStaking _contract;
        uint256 _minimum;
    }

    uint256 constant UINT16_MAX = 2**16 - 1;

    // The maximum number of KEEP tokens in existence.
    // This is used to enforce invariants of the pool,
    // specifically that the minimum stake is high enough
    // that the pool can never "clog"
    // and become unable to accept eligible stakers
    // under any possible circumstances.
    uint256 constant TOKEN_SUPPLY = 10**27;
    // In the worst-case scenario,
    // each trunk can hold one operator with 2^15 weight,
    // after which no operator with 2^15 weight or more can be inserted.
    // However, an operator with 2^15 - 1 weight still fits.
    // This means that the absolute maximum capacity of the pool
    // is 2^15 * 17 - 1.
    uint256 constant POOL_CAPACITY = 2**15 * 17 - 1;
    // The pool capacity doesn't divide the token supply cleanly,
    // leaving a nonzero remainder.
    // However, the minimum stake is vastly greater than the pool capacity,
    // so the remainder cannot exceed the minimum stake.
    uint256 constant REQUIRED_MINIMUM_STAKE = TOKEN_SUPPLY / POOL_CAPACITY;

    uint256 constant GAS_DEPOSIT_SIZE = 1;

    StakingParams staking;

    // The contract (e.g. Keep factory) this specific pool serves.
    // Only the pool owner can request groups.
    address poolOwner;

    constructor (
        IStaking _stakingContract,
        uint256 _minimumStake,
        address _poolOwner
    ) internal {
        require(
            isSufficientMinimumStake(_minimumStake),
            "Insufficient minimum stake"
        );
        staking = StakingParams(_stakingContract, _minimumStake);
        poolOwner = _poolOwner;
    }

    // Return whether the operator is eligible for the pool.
    function isOperatorEligible(address operator) public view returns (bool) {
        return getEligibleWeight(operator) > 0;
    }

    // Return whether the operator is present in the pool.
    function isOperatorInPool(address operator) public view returns (bool) {
        return getFlaggedOperatorLeaf(operator) != 0;
    }

    // Return whether the operator's weight in the pool
    // matches their eligible weight.
    function isOperatorUpToDate(address operator) public view returns (bool) {
        return getEligibleWeight(operator) == getPoolWeight(operator);
    }

    // Return the weight of the operator in the pool,
    // which may or may not be out of date.
    function getPoolWeight(address operator) public view returns (uint256) {
        uint256 flaggedLeaf = getFlaggedOperatorLeaf(operator);
        if (flaggedLeaf == 0) {
            return 0;
        } else {
            uint256 leafPosition = flaggedLeaf.unsetFlag();
            uint256 leafWeight = leaves[leafPosition].weight();
            return leafWeight;
        }
    }

    // Add an operator to the pool,
    // reverting if the operator is already present.
    function joinPool(address operator) public {
        uint256 eligibleWeight = getEligibleWeight(operator);
        require(
            eligibleWeight > 0,
            "Operator not eligible"
        );
        require(
            eligibleWeight <= UINT16_MAX,
            "Operator weights above 65535 are not supported"
        );

        depositGas(operator);
        insertOperator(operator, eligibleWeight);
    }

    // Update the operator's weight if present and eligible,
    // or remove from the pool if present and ineligible.
    function updateOperatorStatus(address operator) public {
        uint256 eligibleWeight = getEligibleWeight(operator);
        uint256 inPoolWeight = getPoolWeight(operator);

        require(
            inPoolWeight > 0,
            "Operator is not registered in the pool"
        );
        require(
            eligibleWeight != inPoolWeight,
            "Operator already up to date"
        );
        require(
            eligibleWeight <= UINT16_MAX,
            "Operator weights above 65535 are not supported"
        );

        if (eligibleWeight == 0) {
            removeFromPool(operator);
        } else {
            updateOperator(operator, eligibleWeight);
        }
    }

    function removeFromPool(address operator) internal {
        removeOperator(operator);
        releaseGas(operator);
    }

    // Return the eligible weight of the operator,
    // which may differ from the weight in the pool.
    // Return 0 if ineligible.
    function getEligibleWeight(address operator) internal view returns (uint256);

    function gasDepositSize() internal pure returns (uint256) {
        return GAS_DEPOSIT_SIZE;
    }

    function isSufficientMinimumStake(uint256 amount) internal pure returns (bool) {
        return amount > REQUIRED_MINIMUM_STAKE;
    }
}
