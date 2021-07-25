pragma solidity 0.5.17;

import "./AbstractSortitionPool.sol";
import "./RNG.sol";
import "./DynamicArray.sol";
import "./api/IFullyBackedBonding.sol";

/// @title Fully Backed Sortition Pool
/// @notice A logarithmic data structure
/// used to store the pool of eligible operators weighted by their stakes.
/// It allows to select a group of operators
/// based on the provided pseudo-random seed and bonding requirements.
/// The fully backed pool uses bonds instead of stakes
/// to determine the eligibility and weight of operators.
/// When operators are selected,
/// the pool updates their weight to reflect their lower available bonds.
/// @dev Keeping pool up to date cannot be done eagerly
/// as proliferation of privileged customers could be used
/// to perform DOS attacks by increasing the cost of such updates.
/// When a sortition pool prospectively selects an operator,
/// the selected operator’s eligibility status and weight needs to be checked
/// and, if necessary, updated in the sortition pool.
/// If the changes would be detrimental to the operator,
/// the operator selection is performed again with the updated input
/// to ensure correctness.
/// The pool should specify a reasonable minimum bondable value for operators
/// trying to join the pool, to prevent griefing the selection.
contract FullyBackedSortitionPool is AbstractSortitionPool {
  using DynamicArray for DynamicArray.UintArray;
  using DynamicArray for DynamicArray.AddressArray;
  using RNG for RNG.State;
  // The pool should specify a reasonable minimum bond
  // for operators trying to join the pool,
  // to prevent griefing by operators joining without enough bondable value.
  // After we start selecting groups
  // this value can be set to equal the most recent request's bondValue.

  struct PoolParams {
    IFullyBackedBonding bondingContract;
    // Defines the minimum unbounded value the operator needs to have to be
    // eligible to join and stay in the sortition pool. Operators not
    // satisfying minimum bondable value are removed from the pool.
    uint256 minimumBondableValue;
    // Bond required from each operator for the currently pending group
    // selection. If operator does not have at least this unbounded value,
    // it is skipped during the selection.
    uint256 requestedBond;
    // Because the minimum available bond may fluctuate,
    // we use a constant pool weight divisor.
    // When we receive the available bond,
    // we divide it by the constant bondWeightDivisor
    // to get the applicable weight.
    uint256 bondWeightDivisor;
    address owner;
  }

  PoolParams poolParams;

  // Banned operator addresses. Banned operators are removed from the pool; they
  // won't be selected to groups and won't be able to join the pool.
  mapping(address => bool) public bannedOperators;

  constructor(
    IFullyBackedBonding _bondingContract,
    uint256 _initialMinimumBondableValue,
    uint256 _bondWeightDivisor,
    address _poolOwner
  ) public {
    require(_bondWeightDivisor > 0, "Weight divisor must be nonzero");

    poolParams = PoolParams(
      _bondingContract,
      _initialMinimumBondableValue,
      0,
      _bondWeightDivisor,
      _poolOwner
    );
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
  ) public onlyOwner() returns (address[] memory) {
    PoolParams memory params = initializeSelectionParams(bondValue);

    uint256 paramsPtr;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      paramsPtr := params
    }
    return generalizedSelectGroup(groupSize, seed, paramsPtr, true);
  }

  /// @notice Sets the minimum bondable value required from the operator
  /// so that it is eligible to be in the pool. The pool should specify
  /// a reasonable minimum requirement for operators trying to join the pool
  /// to prevent griefing group selection.
  /// @param minimumBondableValue The minimum bondable value required from the
  /// operator.
  function setMinimumBondableValue(uint256 minimumBondableValue) public {
    require(
      msg.sender == poolParams.owner,
      "Only owner may update minimum bond value"
    );

    poolParams.minimumBondableValue = minimumBondableValue;
  }

  /// @notice Returns the minimum bondable value required from the operator
  /// so that it is eligible to be in the pool.
  function getMinimumBondableValue() public view returns (uint256) {
    return poolParams.minimumBondableValue;
  }

  /// @notice Bans an operator in the pool. The operator is added to banned
  /// operators list. If the operator is already registered in the pool it gets
  /// removed. Only onwer of the pool can call this function.
  /// @param operator An operator address.
  function ban(address operator) public onlyOwner() {
    bannedOperators[operator] = true;

    if (isOperatorRegistered(operator)) {
      removeOperator(operator);
    }
  }

  function initializeSelectionParams(uint256 bondValue)
    internal
    returns (PoolParams memory params)
  {
    params = poolParams;

    if (params.requestedBond != bondValue) {
      params.requestedBond = bondValue;
    }

    return params;
  }

  // Return the eligible weight of the operator,
  // which may differ from the weight in the pool.
  // Return 0 if ineligible.
  function getEligibleWeight(address operator) internal view returns (uint256) {
    // Check if the operator has been banned.
    if (bannedOperators[operator]) {
      return 0;
    }

    address ownerAddress = poolParams.owner;
    // Get the amount of bondable value available for this pool.
    // We only care that this covers one single bond
    // regardless of the weight of the operator in the pool.
    uint256 bondableValue = poolParams.bondingContract.availableUnbondedValue(
      operator,
      ownerAddress,
      address(this)
    );

    // Don't query stake if bond is insufficient.
    if (bondableValue < poolParams.minimumBondableValue) {
      return 0;
    }

    // Check if a bonding delegation is initialized.
    bool isBondingInitialized = poolParams.bondingContract.isInitialized(
      operator,
      ownerAddress
    );

    // If a delegation is not yet initialized return 0 = ineligible.
    if (!isBondingInitialized) {
      return 0;
    }

    // Weight = floor(eligibleStake / mimimumStake)
    // Ethereum uint256 division performs implicit floor
    return (bondableValue / poolParams.bondWeightDivisor);
  }

  function decideFate(
    uint256 leaf,
    uint256 leafWeight,
    DynamicArray.AddressArray memory, // `selected`, for future use
    uint256 paramsPtr
  ) internal view returns (Fate memory) {
    PoolParams memory params;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      params := paramsPtr
    }
    address operator = leaf.operator();

    if (!isLeafInitialized(leaf)) {
      return Fate(Decision.Skip, 0);
    }

    address ownerAddress = params.owner;

    // Get the bond-stake available for this selection,
    // before accounting for the bond created if the operator is selected.
    uint256 preStake = params.bondingContract.availableUnbondedValue(
      operator,
      ownerAddress,
      address(this)
    );

    // If unbonded value is insufficient for the operator to be in the pool,
    // delete the operator.
    if (preStake < params.minimumBondableValue) {
      return Fate(Decision.Delete, 0);
    }

    // If unbonded value is sufficient for the operator to be in the pool
    // but it is not sufficient for the current selection, skip the operator.
    if (preStake < params.requestedBond) {
      return Fate(Decision.Skip, 0);
    }

    // Calculate the bond-stake that would be left after selection
    // Doesn't underflow because preStake >= minimum
    uint256 postStake = preStake - params.minimumBondableValue;

    // Calculate the eligible pre-selection weight
    // based on the constant weight divisor.
    uint256 preWeight = preStake / params.bondWeightDivisor;

    // The operator is detrimentally out of date,
    // but still eligible.
    // Because the bond-stake may be shared with other pools,
    // we don't punish this case.
    // Instead, update and retry.
    if (preWeight < leafWeight) {
      return Fate(Decision.UpdateRetry, preWeight);
    }

    // Calculate the post-selection weight
    // based on the constant weight divisor
    uint256 postWeight = postStake / params.bondWeightDivisor;

    // This can result in zero weight,
    // in which case the operator is still in the pool
    // and can return to eligibility after adding more bond.
    // Not sure if we want to do this exact thing,
    // but reasonable to begin with.
    return Fate(Decision.UpdateSelect, postWeight);
  }

  modifier onlyOwner() {
    require(msg.sender == poolParams.owner, "Caller is not the owner");
    _;
  }
}
