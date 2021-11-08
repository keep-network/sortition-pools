pragma solidity 0.8.6;

import "./SortitionPool.sol";
import "./api/IStaking.sol";

/// @title Sortition Pool Factory
/// @notice Factory for the creation of new sortition pools.
contract SortitionPoolFactory {
  event SortitionPoolCreated(address sortitionPoolAddress);

  /// @notice Creates a new sortition pool instance.
  /// @return Address of the new sortition pool contract instance.
  function createSortitionPool(
    IStaking stakingContract,
    uint256 minimumStake,
    uint256 poolWeightDivisor
  ) public returns (address) {
    SortitionPool sortitionPool =
      new SortitionPool(
        stakingContract,
        minimumStake,
        poolWeightDivisor
      );

    sortitionPool.transferOwnership(msg.sender);

    emit SortitionPoolCreated(address(sortitionPool));
    return address(sortitionPool);
  }
}
