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
        staking = StakingParams(_stakingContract, _minimumStake);
        poolParams = PoolParams(_poolOwner);
    }

    struct SelectionParams {
        StakingParams _staking;
        PoolParams _pool;
    }

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
        SelectionParams memory params = initializeSelectionParams();
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
            false
        );
    }

    function initializeSelectionParams()
        internal view returns (SelectionParams memory params)
    {
        StakingParams memory _staking = staking;
        PoolParams memory _pool = poolParams;

        params = SelectionParams(
            _staking,
            _pool
        );
        return params;
    }

    // Return the eligible weight of the operator,
    // which may differ from the weight in the pool.
    // Return 0 if ineligible.
    function getEligibleWeight(address operator) internal view returns (uint256) {
        return queryEligibleWeight(operator, staking, poolParams);
    }

    function queryEligibleWeight(
        address operator,
        StakingParams memory _staking,
        PoolParams memory _pool
    ) internal view returns (uint256) {
        uint256 operatorStake = _staking._contract.eligibleStake(
            operator,
            _pool._owner
        );
        uint256 operatorWeight = operatorStake / _staking._minimum;

        return operatorWeight;
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
        uint256 createdAt = leaf.creationBlock();
        uint256 leafWeight = leaf.weight();

        if (createdAt + INIT_BLOCKS >= block.number) {
            return Decision.Skip;
        }

        address ownerAddress = params._pool._owner;

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
