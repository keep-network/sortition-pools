pragma solidity 0.8.6;

import "./DynamicArray.sol";
import "./RNG.sol";
import "./SortitionTree.sol";
import "./Rewards.sol";
import "./api/IStaking.sol";

/// @title Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed.
contract SortitionPool is SortitionTree, Rewards {
  using Branch for uint256;
  using Leaf for uint256;
  using Position for uint256;
  using DynamicArray for DynamicArray.UintArray;
  using DynamicArray for DynamicArray.AddressArray;

  struct PoolParams {
    IStaking stakingContract;
    uint256 minimumStake;
    uint256 poolWeightDivisor;
    address owner;
  }

  PoolParams internal poolParams;

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

  function payReward(uint256 amount) public {
    Rewards.addRewards(uint96(amount), uint32(root.sumWeight()));
  }

  function withdrawRewards(address operator) public returns (uint256) {
    Rewards.updateOperatorRewards(operator, uint32(getPoolWeight(operator)));
    uint96 earned = Rewards.withdrawOperatorRewards(operator);
    return uint256(earned);
  }

  /// @notice Add an operator to the pool,
  /// reverting if the operator is already present.
  function joinPool(address operator) public {
    uint256 eligibleWeight = getEligibleWeight(operator);
    require(eligibleWeight > 0, "Operator not eligible");

    insertOperator(operator, eligibleWeight);

    Rewards.operatorRewards[operator].accumulated = Rewards
      .globalRewardAccumulator;
  }

  /// @notice Update the operator's weight if present and eligible,
  /// or remove from the pool if present and ineligible.
  function updateOperatorStatus(address operator) public {
    uint256 eligibleWeight = getEligibleWeight(operator);
    uint256 inPoolWeight = getPoolWeight(operator);

    require(eligibleWeight != inPoolWeight, "Operator already up to date");

    Rewards.updateOperatorRewards(operator, uint32(inPoolWeight));

    if (eligibleWeight == 0) {
      removeOperator(operator);
    } else {
      updateOperator(operator, eligibleWeight);
    }
  }

  /// @notice Return whether the operator is eligible for the pool.
  function isOperatorEligible(address operator) public view returns (bool) {
    return getEligibleWeight(operator) > 0;
  }

  /// @notice Return whether the operator is present in the pool.
  function isOperatorInPool(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  /// @notice Return whether the operator's weight in the pool
  /// matches their eligible weight.
  function isOperatorUpToDate(address operator) public view returns (bool) {
    return getEligibleWeight(operator) == getPoolWeight(operator);
  }

  /// @notice Return the weight of the operator in the pool,
  /// which may or may not be out of date.
  function getPoolWeight(address operator) public view returns (uint256) {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    if (flaggedPosition == 0) {
      return 0;
    } else {
      uint256 leafPosition = flaggedPosition.unsetFlag();
      uint256 leafWeight = getLeafWeight(leafPosition);
      return leafWeight;
    }
  }

  /// @notice Selects a new group of operators of the provided size based on
  /// the provided pseudo-random seed. At least one operator has to be
  /// registered in the pool, otherwise the function fails reverting the
  /// transaction.
  /// @param groupSize Size of the requested group
  /// @param seed Pseudo-random number used to select operators to group
  /// @return selected Members of the selected group
  function selectGroup(uint256 groupSize, bytes32 seed)
    public
    view
    returns (address[] memory)
  {
    require(msg.sender == poolParams.owner, "Only owner may select groups");

    uint256 _root = root;

    DynamicArray.UintArray memory selected;
    selected = DynamicArray.uintArray(groupSize);

    bytes32 rngState = seed;
    uint256 rngRange = _root.sumWeight();
    require(rngRange > 0, "Not enough operators in pool");
    uint256 currentIndex;

    uint256 bits = RNG.bitsRequired(rngRange);

    while (selected.array.length < groupSize) {
      (currentIndex, rngState) = RNG.getIndex(rngRange, rngState, bits);

      uint256 leafPosition = pickWeightedLeaf(currentIndex, _root);

      uint256 leaf = leaves[leafPosition];
      selected.arrayPush(leaf);
    }

    address[] memory selectedAddresses = new address[](groupSize);

    for (uint256 i = 0; i < groupSize; i++) {
      selectedAddresses[i] = selected.array[i].operator();
    }
    return selectedAddresses;
  }

  /// @notice Return the eligible weight of the operator,
  /// which may differ from the weight in the pool.
  /// Return 0 if ineligible.
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
