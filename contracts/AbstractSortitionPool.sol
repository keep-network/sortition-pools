pragma solidity 0.5.17;

import "./RNG.sol";
import "./SortitionTree.sol";
import "./DynamicArray.sol";
import "./api/IStaking.sol";

/// @title Abstract Sortition Pool
/// @notice Abstract contract encapsulating common logic of all sortition pools.
/// @dev Inheriting implementations are expected to implement getEligibleWeight
/// function.
contract AbstractSortitionPool is SortitionTree {
  using Leaf for uint256;
  using Position for uint256;
  using DynamicArray for DynamicArray.UintArray;
  using DynamicArray for DynamicArray.AddressArray;
  using RNG for RNG.State;

  enum Decision {
    Select, // Add to the group, and use new seed
    Skip, // Retry with same seed, skip this leaf
    Delete, // Retry with same seed, delete this leaf
    UpdateRetry, // Retry with same seed, update this leaf
    UpdateSelect // Select and reseed, but also update this leaf
  }

  struct Fate {
    Decision decision;
    // The new weight of the leaf if Decision is Update*, otherwise 0
    uint256 maybeWeight;
  }

  // Require 10 blocks after joining before the operator can be selected for
  // a group. This reduces the degrees of freedom miners and other
  // front-runners have in conducting pool-bumping attacks.
  //
  // We don't use the stack of empty leaves until we run out of space on the
  // rightmost leaf (i.e. after 2 million operators have joined the pool).
  // It means all insertions are at the right end, so one can't reorder
  // operators already in the pool until the pool has been filled once.
  // Because the index is calculated by taking the minimum number of required
  // random bits, and seeing if it falls in the range of the total pool weight,
  // the only scenarios where insertions on the right matter are if it crosses
  // a power of two threshold for the total weight and unlocks another random
  // bit, or if a random number that would otherwise be discarded happens to
  // fall within that space.
  uint256 constant INIT_BLOCKS = 10;

  uint256 constant GAS_DEPOSIT_SIZE = 1;

  /// @notice The number of blocks that must be mined before the operator who
  // joined the pool is eligible for work selection.
  function operatorInitBlocks() public pure returns (uint256) {
    return INIT_BLOCKS;
  }

  // Return whether the operator is eligible for the pool.
  function isOperatorEligible(address operator) public view returns (bool) {
    return getEligibleWeight(operator) > 0;
  }

  // Return whether the operator is present in the pool.
  function isOperatorInPool(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  // Return whether the operator's weight in the pool
  // matches their eligible weight.
  function isOperatorUpToDate(address operator) public view returns (bool) {
    return getEligibleWeight(operator) == getPoolWeight(operator);
  }

  // Returns whether the operator has passed the initialization blocks period
  // to be eligible for the work selection. Reverts if the operator is not in
  // the pool.
  function isOperatorInitialized(address operator) public view returns (bool) {
    require(isOperatorInPool(operator), "Operator is not in the pool");

    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    uint256 leafPosition = flaggedPosition.unsetFlag();
    uint256 leaf = leaves[leafPosition];

    return isLeafInitialized(leaf);
  }

  // Return the weight of the operator in the pool,
  // which may or may not be out of date.
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

  // Add an operator to the pool,
  // reverting if the operator is already present.
  function joinPool(address operator) public {
    uint256 eligibleWeight = getEligibleWeight(operator);
    require(eligibleWeight > 0, "Operator not eligible");

    insertOperator(operator, eligibleWeight);
  }

  // Update the operator's weight if present and eligible,
  // or remove from the pool if present and ineligible.
  function updateOperatorStatus(address operator) public {
    uint256 eligibleWeight = getEligibleWeight(operator);
    uint256 inPoolWeight = getPoolWeight(operator);

    require(eligibleWeight != inPoolWeight, "Operator already up to date");

    if (eligibleWeight == 0) {
      removeOperator(operator);
    } else {
      updateOperator(operator, eligibleWeight);
    }
  }

  function generalizedSelectGroup(
    uint256 groupSize,
    bytes32 seed
  ) internal returns (uint256[] memory) {
    uint256 _root = root;

    DynamicArray.UintArray memory selected;
    selected = DynamicArray.uintArray(groupSize);

    RNG.State memory rng;
    rng = RNG.initialize(seed, _root.sumWeight(), groupSize);

    while (selected.array.length < groupSize) {
      rng.generateNewIndex();

      (uint256 leafPosition,,)
        = pickWeightedLeaf(
        rng.currentMappedIndex,
        _root
      );

      uint256 leaf = leaves[leafPosition];
      selected.arrayPush(leaf);
    }
    return selected.array;
  }

  function isLeafInitialized(uint256 leaf) internal view returns (bool) {
    uint256 createdAt = leaf.creationBlock();

    return block.number > (createdAt + operatorInitBlocks());
  }

  // Return the eligible weight of the operator,
  // which may differ from the weight in the pool.
  // Return 0 if ineligible.
  function getEligibleWeight(address operator) internal view returns (uint256);
}
