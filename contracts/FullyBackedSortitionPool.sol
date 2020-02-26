pragma solidity ^0.5.10;

import "./AbstractSortitionPool.sol";
import "./RNG.sol";
import "./api/IStaking.sol";
import "./api/IBonding.sol";
import "./DynamicArray.sol";

/// @title Fully Backed Sortition Pool
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
contract FullyBackedSortitionPool is AbstractSortitionPool {
    using DynamicArray for DynamicArray.UintArray;
    using DynamicArray for DynamicArray.AddressArray;
    using RNG for RNG.State;
    // The pool should specify a reasonable minimum bond
    // for operators trying to join the pool,
    // to prevent griefing by operators joining without enough bondable value.
    // After we start selecting groups
    // this value can be set to equal the most recent request's bondValue.

    struct PoolParams {
        IBonding bondingContract;
        uint256 minimumAvailableBond;
        // Because the minimum available stake may fluctuate,
        // we use a constant pool weight divisor.
        // When we receive the available stake,
        // we divide it by the constant poolWeightDivisor
        // to get the applicable weight.
        uint256 poolWeightDivisor;
        address owner;
    }

    PoolParams poolParams;

    constructor(
        IBonding _bondingContract,
        uint256 _initialMinimumStake,
        uint256 _poolWeightDivisor,
        address _poolOwner
    ) public {
        require(_poolWeightDivisor > 0, "Weight divisor must be nonzero");

        poolParams = PoolParams(
            _bondingContract,
            _initialMinimumStake,
            _poolWeightDivisor,
            _poolOwner
        );
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
        PoolParams memory params = initializeSelectionParams(
            bondValue
        );
        require(
            msg.sender == params.owner,
            "Only owner may select groups"
        );
        uint256 paramsPtr;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            paramsPtr := params
        }
        return generalizedSelectGroup(
            groupSize,
            seed,
            paramsPtr,
            true
        );
    }

    function initializeSelectionParams(
        uint256 bondValue
    ) internal returns (PoolParams memory params) {
        params = poolParams;

        if (params.minimumAvailableBond != bondValue) {
            params.minimumAvailableBond = bondValue;
            poolParams.minimumAvailableBond = bondValue;
        }

        return params;
    }

    // Return the eligible weight of the operator,
    // which may differ from the weight in the pool.
    // Return 0 if ineligible.
    function getEligibleWeight(address operator) internal view returns (uint256) {
        address ownerAddress = poolParams.owner;
        // Get the amount of bondable value available for this pool.
        // We only care that this covers one single bond
        // regardless of the weight of the operator in the pool.
        uint256 bondableValue = poolParams.bondingContract.availableUnbondedValue(
            operator,
            ownerAddress,
            address(this)
        );

        // Don't query stake if bond is insufficient.
        if (bondableValue < poolParams.minimumAvailableBond) {
            return 0;
        }

        // Weight = floor(eligibleStake / mimimumStake)
        // Ethereum uint256 division performs implicit floor
        // If eligibleStake < minimumStake, return 0 = ineligible.
        return (bondableValue / poolParams.poolWeightDivisor);
    }

    function decideFate(
        uint256 leaf,
        DynamicArray.AddressArray memory, // `selected`, for future use
        uint256 paramsPtr
    ) internal view returns (Fate memory) {
        PoolParams memory params;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            params := paramsPtr
        }
        address operator = leaf.operator();
        uint256 leafWeight = leaf.weight();

        if (!isLeafInitialized(leaf)) {
            return Fate(Decision.Skip, 0);
        }

        address ownerAddress = params.owner;

        // Get the bond-stake available for this selection,
        // before accounting for the bond created if the operator is selected.
        uint256 preStake = params.bondingContract.availableUnbondedValue(
            operator,
            ownerAddress,
            address(this)
        );


        // Don't proceed further if bond is insufficient.
        if (preStake < params.minimumAvailableBond) {
            return Fate(Decision.Delete, 0);
        }

        // Calculate the bond-stake that would be left after selection
        // Doesn't underflow because preStake >= minimum
        uint256 postStake = preStake - params.minimumAvailableBond;

        // Calculate the eligible pre-selection weight
        // based on the constant weight divisor.
        uint256 preWeight = preStake / params.poolWeightDivisor;

        // The operator is detrimentally out of date,
        // but still eligible.
        // Because the bond-stake may be shared with other pools,
        // we don't punish this case.
        // Instead, update and retry.
        if (preWeight < leafWeight) {
            return Fate(Decision.UpdateRetry, preWeight);
        }

        // Calculate the post-selection weight
        // based on the constant weight divisor
        uint256 postWeight = postStake / params.poolWeightDivisor;

        // This can result in zero weight,
        // in which case the operator is still in the pool
        // and can return to eligibility after adding more bond.
        // Not sure if we want to do this exact thing,
        // but reasonable to begin with.
        return Fate(Decision.UpdateSelect, postWeight);
    }
}
