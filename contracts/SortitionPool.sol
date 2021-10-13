pragma solidity 0.5.17;

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
    uint256 _poolWeightDivisor,
    address _poolOwner
  ) public {
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
    require(msg.sender == poolParams.owner, "Only owner may select groups");
    uint256[] memory selected = generalizedSelectGroup(
        groupSize, seed
    );
    address[] memory selectedAddresses = new address[](groupSize);
    for (uint256 i = 0; i < selected.length; i++) {
      selectedAddresses[i] = selected[i].operator();
    }
    return selectedAddresses;
  }

  // Return the eligible weight of the operator,
  // which may differ from the weight in the pool.
  // Return 0 if ineligible.
  function getEligibleWeight(address operator) internal view returns (uint256) {
    PoolParams memory params = poolParams;
    uint256 operatorStake = params.stakingContract.eligibleStake(
      operator,
      params.owner
    );
    if (operatorStake < params.minimumStake) {
      return 0;
    }
    return operatorStake / params.poolWeightDivisor;
  }
}
