pragma solidity 0.8.6;

import "./DynamicArray.sol";
import "./RNG.sol";
import "./SortitionTree.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed.
contract SortitionPool is SortitionTree, Ownable {
  using Branch for uint256;
  using Leaf for uint256;
  using Position for uint256;
  using DynamicArray for DynamicArray.UintArray;
  using DynamicArray for DynamicArray.AddressArray;

  uint256 public immutable poolWeightDivisor;

  bool public isLocked;

  /// @notice Reverts if called while pool is locked.
  modifier onlyUnlocked() {
    require(!isLocked, "Sortition pool locked");
    _;
  }

  constructor(uint256 _poolWeightDivisor) {
    poolWeightDivisor = _poolWeightDivisor;
  }

  /// @notice Locks the sortition pool. In locked state, members cannot be
  ///         inserted and removed from the pool. Members statuses cannot
  ///         be updated as well.
  /// @dev Can be called only by the contract owner.
  function lock() public onlyOwner {
    isLocked = true;
  }

  /// @notice Unlocks the sortition pool. Removes all restrictions set by
  ///         the `lock` method.
  /// @dev Can be called only by the contract owner.
  function unlock() public onlyOwner {
    isLocked = false;
  }

  /// @notice Inserts an operator to the pool. Reverts if the operator is
  /// already present.
  /// @dev Can be called only by the contract owner.
  /// @param operator Address of the inserted operator.
  /// @param authorizedStake Inserted operator's authorized stake for the application.
  function insertOperator(address operator, uint256 authorizedStake)
    public
    onlyOwner
    onlyUnlocked
  {
    uint256 weight = getWeight(authorizedStake);
    require(weight > 0, "Operator not eligible");

    _insertOperator(operator, weight);
  }

  /// @notice Update the operator's weight if present and eligible,
  /// or remove from the pool if present and ineligible.
  /// @dev Can be called only by the contract owner.
  /// @param operator Address of the updated operator.
  /// @param authorizedStake Operator's authorized stake for the application.
  function updateOperatorStatus(address operator, uint256 authorizedStake)
    public
    onlyOwner
    onlyUnlocked
  {
    uint256 weight = getWeight(authorizedStake);

    if (weight == 0) {
      _removeOperator(operator);
    } else {
      updateOperator(operator, weight);
    }
  }

  /// @notice Removes an operator from the pool.
  /// @dev Can be called only by the contract owner.
  /// @param operator Address of the operator to be removed.
  function removeOperator(address operator) public onlyOwner onlyUnlocked {
    _removeOperator(operator);
  }

  /// @notice Ban rewards for given operators for given period of time.
  /// @dev Can be called only by the contract owner.
  /// @param operators IDs of banned operators.
  /// @param duration Duration of the ban in seconds.
  function banRewards(uint32[] calldata operators, uint256 duration)
    external
    onlyOwner
  {
    // TODO: Implementation
  }

  /// @notice Return whether the operator is present in the pool.
  function isOperatorInPool(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  /// @notice Return whether the operator's weight in the pool
  /// matches their eligible weight.
  function isOperatorUpToDate(address operator, uint256 authorizedStake)
    public
    view
    returns (bool)
  {
    return getWeight(authorizedStake) == getPoolWeight(operator);
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
    returns (uint32[] memory)
  {
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

    uint32[] memory selectedIDs = new uint32[](groupSize);

    for (uint256 i = 0; i < groupSize; i++) {
      selectedIDs[i] = selected.array[i].id();
    }
    return selectedIDs;
  }

  function getWeight(uint256 authorization) internal view returns (uint256) {
    return authorization / poolWeightDivisor;
  }
}
