pragma solidity ^0.5.10;

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
    struct BondingParams {
        IBonding _contract;
        uint256 _minimumBondableValue;
    }

    struct SelectionParams {
        StakingParams _staking;
        BondingParams _bonding;
        PoolParams _pool;
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
        poolParams = PoolParams(_poolOwner);
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
        SelectionParams memory params = initializeSelectionParams(
            bondValue
        );
        require(
            msg.sender == params._pool._owner,
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
    ) internal returns (SelectionParams memory params) {
        StakingParams memory _staking = staking;
        BondingParams memory _bonding = bonding;
        PoolParams memory _pool = poolParams;

        if (_bonding._minimumBondableValue != bondValue) {
            _bonding._minimumBondableValue = bondValue;
            bonding._minimumBondableValue = bondValue;
        }

        params = SelectionParams(
            _staking,
            _bonding,
            _pool
        );
        return params;
    }

    // Return the eligible weight of the operator,
    // which may differ from the weight in the pool.
    // Return 0 if ineligible.
    function getEligibleWeight(address operator) internal view returns (uint256) {
        address ownerAddress = poolParams._owner;
        // Get the amount of bondable value available for this pool.
        // We only care that this covers one single bond
        // regardless of the weight of the operator in the pool.
        uint256 bondableValue = bonding._contract.availableUnbondedValue(
            operator,
            ownerAddress,
            address(this)
        );

        // Don't query stake if bond is insufficient.
        if (bondableValue < bonding._minimumBondableValue) {
            return 0;
        }

        uint256 eligibleStake = staking._contract.eligibleStake(
            operator,
            ownerAddress
        );

        // Weight = floor(eligibleStake / mimimumStake)
        // Ethereum uint256 division performs implicit floor
        // If eligibleStake < minimumStake, return 0 = ineligible.
        return (eligibleStake / staking._minimum);
    }

    function decideFate(
        uint256 leaf,
        DynamicArray.AddressArray memory, // `selected`, for future use
        uint256 paramsPtr
    ) internal view returns (Decision) {
        SelectionParams memory params;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            params := paramsPtr
        }
        address operator = leaf.operator();
        uint256 leafWeight = leaf.weight();

        if (!isLeafInitialized(leaf)) {
            return Decision.Skip;
        }

        address ownerAddress = params._pool._owner;

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
            return Decision.Delete;
        }

        uint256 eligibleStake = params._staking._contract.eligibleStake(
            operator,
            ownerAddress
        );

        // Weight = floor(eligibleStake / mimimumStake)
        // Ethereum uint256 division performs implicit floor
        uint256 eligibleWeight = eligibleStake / params._staking._minimum;

        if (eligibleWeight < leafWeight) {
            return Decision.Delete;
        }
        return Decision.Select;
    }
}
