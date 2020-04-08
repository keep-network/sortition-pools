pragma solidity 0.5.17;

import "./AbstractSortitionPool.sol";
import "./RNG.sol";
import "./api/IStaking.sol";
import "./api/IBonding.sol";
import "./DynamicArray.sol";

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
    using DynamicArray for DynamicArray.UintArray;
    using DynamicArray for DynamicArray.AddressArray;
    using RNG for RNG.State;
    // The pool should specify a reasonable minimum bond
    // for operators trying to join the pool,
    // to prevent griefing by operators joining without enough bondable value.
    // After we start selecting groups
    // this value can be set to equal the most recent request's bondValue.

    struct PoolParams {
        IStaking stakingContract;
        uint256 minimumStake;
        IBonding bondingContract;
        uint256 minimumBondableValue;
        // The weight divisor in the pool can differ from the minimum stake
        uint256 poolWeightDivisor;
        address owner;
    }

    PoolParams poolParams;

    constructor(
        IStaking _stakingContract,
        IBonding _bondingContract,
        uint256 _minimumStake,
        uint256 _minimumBondableValue,
        uint256 _poolWeightDivisor,
        address _poolOwner
    ) public {
        require(_minimumStake > 0, "Minimum stake cannot be zero");

        poolParams = PoolParams(
            _stakingContract,
            _minimumStake,
            _bondingContract,
            _minimumBondableValue,
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
    /// @param minimumStake The current minimum stake value
    /// @param bondValue Size of the requested bond per operator
    function selectSetGroup(
        uint256 groupSize,
        bytes32 seed,
        uint256 minimumStake,
        uint256 bondValue
    ) public returns (address[] memory) {
        PoolParams memory params = initializeSelectionParams(
            minimumStake,
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
        uint256 currentMinimumStake,
        uint256 bondValue
    ) internal returns (PoolParams memory params) {
        params = poolParams;

        if (params.minimumBondableValue != bondValue) {
            params.minimumBondableValue = bondValue;
            poolParams.minimumBondableValue = bondValue;
        }

        if (params.minimumStake != currentMinimumStake) {
            params.minimumStake = currentMinimumStake;
            poolParams.minimumStake = currentMinimumStake;
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
        if (bondableValue < poolParams.minimumBondableValue) {
            return 0;
        }

        uint256 eligibleStake = poolParams.stakingContract.eligibleStake(
            operator,
            ownerAddress
        );

        if (eligibleStake < poolParams.minimumStake) { return 0; }

        // Weight = floor(eligibleStake / poolWeightDivisor)
        // Ethereum uint256 division performs implicit floor
        // If eligibleStake < poolWeightDivisor, return 0 = ineligible.
        return (eligibleStake / poolParams.poolWeightDivisor);
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

        // Get the amount of bondable value available for this pool.
        // We only care that this covers one single bond
        // regardless of the weight of the operator in the pool.
        uint256 bondableValue = params.bondingContract.availableUnbondedValue(
            operator,
            ownerAddress,
            address(this)
        );

        // Don't query stake if bond is insufficient.
        if (bondableValue < params.minimumBondableValue) {
            return Fate(Decision.Delete, 0);
        }

        uint256 eligibleStake = params.stakingContract.eligibleStake(
            operator,
            ownerAddress
        );

        // Weight = floor(eligibleStake / poolWeightDivisor)
        // Ethereum uint256 division performs implicit floor
        uint256 eligibleWeight = eligibleStake / params.poolWeightDivisor;

        if (eligibleWeight < leafWeight || eligibleStake < params.minimumStake) {
            return Fate(Decision.Delete, 0);
        }
        return Fate(Decision.Select, 0);
    }
}
