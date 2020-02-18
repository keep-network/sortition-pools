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
        poolParams = PoolParams(_poolOwner, INIT_BLOCKS);
    }

    // Require 10 blocks after joining
    // before the operator can be selected for a group.
    uint256 constant INIT_BLOCKS = 10;

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
        uint256 paramsPtr = initializeSelectionParams();
        return generalizedSelectGroup(
            groupSize,
            seed,
            paramsPtr,
            false
        );
    }

    function initializeSelectionParams() internal returns (uint256 paramsPtr) {
        StakingParams memory _staking = staking;
        PoolParams memory _pool = poolParams;

        SelectionParams memory params = SelectionParams(
            _staking,
            _pool
        );
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            paramsPtr := params
        }
        return paramsPtr;
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
        DynamicArray.AddressArray memory selected,
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

        uint256 initBlocks = params._pool._initBlocks;

        if (createdAt + initBlocks >= block.number) {
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
        // If eligibleStake < minimumStake, return 0 = ineligible.
        if (eligibleWeight < leafWeight) {
            return Decision.Delete;
        } else {
            return Decision.Select;
        }
    }
}
