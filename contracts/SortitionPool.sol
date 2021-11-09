pragma solidity 0.8.6;

import "./DynamicArray.sol";
import "./RNG.sol";
import "./SortitionTree.sol";
import "./api/IStaking.sol";
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

  IStaking public immutable stakingContract;

  uint256 public immutable poolWeightDivisor;

  uint256 public minimumStake;

  bool public isLocked;

  /// @notice Reverts if called while pool is locked.
  modifier onlyUnlocked() {
    require(!isLocked, "Sortition pool locked");
    _;
  }

  constructor(
    IStaking _stakingContract,
    uint256 _minimumStake,
    uint256 _poolWeightDivisor
  ) {
    stakingContract = _stakingContract;
    minimumStake = _minimumStake;
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

  /// @notice Inserts an operator to the pool,
  /// reverting if the operator is already present.
  /// @dev Can be called only by the contract owner.
  /// @param operator Address of the inserted operator.
  function insertOperator(address operator) public onlyOwner onlyUnlocked {
    uint256 eligibleWeight = getEligibleWeight(operator);
    require(eligibleWeight > 0, "Operator not eligible");

    _insertOperator(operator, eligibleWeight);
  }

  /// @notice Removes an operator from the pool.
  /// @dev Can be called only by the contract owner.
  /// @param id ID of the removed operator.
  function removeOperator(uint32 id) public onlyOwner onlyUnlocked {
    _removeOperator(getIDOperator(id));
  }

  /// @notice Removes given operators from the pool.
  /// @dev Can be called only by the contract owner.
  /// @param ids IDs of the removed operators.
  function removeOperators(uint32[] calldata ids)
    public
    onlyOwner
    onlyUnlocked
  {
    address[] memory operators = getIDOperators(ids);

    for (uint256 i = 0; i < operators.length; i++) {
      _removeOperator(operators[i]);
    }
  }

  /// @notice Update the operator's weight if present and eligible,
  /// or remove from the pool if present and ineligible.
  /// @dev Can be called only by the contract owner.
  /// @param id ID of the updated operator.
  function updateOperatorStatus(uint32 id) public onlyOwner onlyUnlocked {
    address operator = getIDOperator(id);

    uint256 eligibleWeight = getEligibleWeight(operator);
    uint256 inPoolWeight = getPoolWeight(operator);

    require(eligibleWeight != inPoolWeight, "Operator already up to date");

    if (eligibleWeight == 0) {
      _removeOperator(operator);
    } else {
      updateOperator(operator, eligibleWeight);
    }
  }

  /// @notice Updates the minimum stake value,
  /// @dev Can be called only by the contract owner.
  /// @param newMinimumStake New minimum stake value.
  function updateMinimumStake(uint256 newMinimumStake) external onlyOwner {
    minimumStake = newMinimumStake;
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
    onlyOwner
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
      selectedIDs[i] = getOperatorID(selected.array[i].operator());
    }
    return selectedIDs;
  }

  /// @notice Return the eligible weight of the operator,
  /// which may differ from the weight in the pool.
  /// Return 0 if ineligible.
  function getEligibleWeight(address operator) internal view returns (uint256) {
    uint256 operatorStake = stakingContract.eligibleStake(operator, owner());
    if (operatorStake < minimumStake) {
      return 0;
    }
    return operatorStake / poolWeightDivisor;
  }
}
