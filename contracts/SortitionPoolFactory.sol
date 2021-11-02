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
    address sortitionPool = address(
      new SortitionPool(
        stakingContract,
        minimumStake,
        poolWeightDivisor,
        msg.sender
      )
    );

    emit SortitionPoolCreated(sortitionPool);
    return sortitionPool;
  }
}
