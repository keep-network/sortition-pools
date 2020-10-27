pragma solidity 0.5.17;

import "./IBonding.sol";

/// @title Fully Backed Bonding contract interface.
/// @notice The interface should be implemented by a bonding contract used for
/// Fully Backed Sortition Pool.
contract IFullyBackedBonding is IBonding {
  /// @notice Checks if the operator for the given bond creator contract
  /// has passed the initialization period.
  /// @param operator The operator address.
  /// @param bondCreator The bond creator contract address.
  /// @return True if operator has passed initialization period for given
  /// bond creator contract, false otherwise.
  function isInitialized(address operator, address bondCreator)
    public
    view
    returns (bool);
}
