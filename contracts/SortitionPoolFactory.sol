pragma solidity ^0.5.10;

import "./SortitionPool.sol";
import "@keep-network/keep-core/contracts/ITokenStaking.sol";

/// @title Sortition Pool Factory
/// @notice Factory for the creation of new sortition pools.
contract SortitionPoolFactory {
    /// @notice Creates a new sortition pool instance.
    /// @return Address of the new sortition pool contract instance.
    function createSortitionPool(
        ITokenStaking stakingContract,
        uint256 minimumStake
    ) public returns (address) {
        return address(
            new SortitionPool(
                stakingContract,
                minimumStake,
                msg.sender
            )
        );
    }
}
