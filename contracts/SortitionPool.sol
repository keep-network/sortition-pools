pragma solidity ^0.5.10;

import "./AbstractSortitionPool.sol";
import "./RNG.sol";
import "./api/IStaking.sol";

/// @title Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed.
/// @dev Keeping pool up to date cannot be done eagerly as proliferation of
/// privileged customers could be used to perform DOS attacks by increasing the
/// cost of such updates. When a sortition pool prospectively selects an
/// operator, the selected operator’s eligibility status and weight needs to be
/// checked and, if necessary, updated in the sortition pool. If the changes
/// would be detrimental to the operator, the operator selection is performed
/// again with the updated input to ensure correctness.
contract SortitionPool is AbstractSortitionPool {
    constructor(
        IStaking _stakingContract,
        uint256 _minimumStake,
        address _poolOwner
    ) public {
        poolParams = PoolParams(
            _stakingContract,
            _minimumStake,
            _poolOwner
        );
    }

    struct PoolParams {
        IStaking stakingContract;
        uint256 minimumStake;
        address owner;
    }

    PoolParams poolParams;

    /// @notice Selects a new group of operators of the provided size based on
    /// the provided pseudo-random seed. At least one operator has to be
    /// registered in the pool, otherwise the function fails reverting the
    /// transaction.
    /// @param groupSize Size of the requested group
    /// @param seed Pseudo-random number used to select operators to group
    /// @return selected Members of the selected group
    function selectGroup(
        uint256 groupSize, bytes32 seed
    ) public returns (address[] memory)  {
        PoolParams memory params = initializeSelectionParams();
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
            false
        );
    }

    function initializeSelectionParams()
        internal returns (PoolParams memory params)
    {
        params = poolParams;

        uint256 currentMinimumStake = params.stakingContract.minimumStake();
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
        return queryEligibleWeight(operator, poolParams);
    }

    function queryEligibleWeight(
        address operator,
        PoolParams memory params
    ) internal view returns (uint256) {
        uint256 minimumStake = poolParams.stakingContract.minimumStake();
        uint256 operatorStake = params.stakingContract.eligibleStake(
            operator,
            params.owner
        );
        uint256 operatorWeight = operatorStake / minimumStake;

        return operatorWeight;
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

        uint256 eligibleStake = params.stakingContract.eligibleStake(
            operator,
            ownerAddress
        );

        // Weight = floor(eligibleStake / mimimumStake)
        // Ethereum uint256 division performs implicit floor
        uint256 eligibleWeight = eligibleStake / params.minimumStake;

        if (eligibleWeight < leafWeight) {
            return Fate(Decision.Delete, 0);
        }
        return Fate(Decision.Select, 0);
    }
}
