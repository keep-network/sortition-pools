// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

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
  using Leaf for uint256;

  constructor(
    IStaking _stakingContract,
    uint256 _minimumStake,
    uint256 _poolWeightDivisor,
    address _poolOwner
  ) {
    poolParams = PoolParams(
      _stakingContract,
      _minimumStake,
      _poolWeightDivisor,
      _poolOwner
    );
  }

  struct PoolParams {
    IStaking stakingContract;
    uint256 minimumStake;
    uint256 poolWeightDivisor;
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
    uint256 groupSize,
    bytes32 seed,
    uint256 minimumStake
  ) public returns (address[] memory) {
    PoolParams memory params = initializeSelectionParams(minimumStake);
    require(msg.sender == params.owner, "Only owner may select groups");
    uint256 paramsPtr;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      paramsPtr := params
    }
    return generalizedSelectGroup(groupSize, seed, paramsPtr, false);
  }

  function initializeSelectionParams(uint256 currentMinimumStake)
    internal
    returns (PoolParams memory params)
  {
    params = poolParams;

    if (params.minimumStake != currentMinimumStake) {
      params.minimumStake = currentMinimumStake;
      poolParams.minimumStake = currentMinimumStake;
    }

    return params;
  }

  // Return the eligible weight of the operator,
  // which may differ from the weight in the pool.
  // Return 0 if ineligible.
  function getEligibleWeight(address operator)
    internal
    view
    override
    returns (uint256)
  {
    return queryEligibleWeight(operator, poolParams);
  }

  function queryEligibleWeight(address operator, PoolParams memory params)
    internal
    view
    returns (uint256)
  {
    uint256 operatorStake = params.stakingContract.eligibleStake(
      operator,
      params.owner
    );
    if (operatorStake < params.minimumStake) {
      return 0;
    }
    return operatorStake / params.poolWeightDivisor;
  }

  function decideFate(
    uint256 leaf,
    DynamicArray.AddressArray memory, // `selected`, for future use
    uint256 paramsPtr
  ) internal view override returns (Fate memory) {
    PoolParams memory params;
    // solhint-disable-next-line no-inline-assembly
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
    uint256 eligibleWeight = eligibleStake / params.poolWeightDivisor;

    if (eligibleWeight < leafWeight || eligibleStake < params.minimumStake) {
      return Fate(Decision.Delete, 0);
    }
    return Fate(Decision.Select, 0);
  }
}
