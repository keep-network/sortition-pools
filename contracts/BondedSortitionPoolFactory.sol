pragma solidity ^0.5.10;

import "./BondedSortitionPool.sol";
import "./BondingContractInterface.sol";

/// @title Bonded Sortition Pool Factory
/// @notice Factory for the creation of new bonded sortition pools.
contract BondedSortitionPoolFactory {
    /// @notice Creates a new bonded sortition pool instance.
    /// @return Address of the new bonded sortition pool contract instance.
    function createSortitionPool() public returns (address) {
        return address(new BondedSortitionPool());
    }
}
