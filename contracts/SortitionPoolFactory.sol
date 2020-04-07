pragma solidity ^0.5.10;

import "./SortitionPool.sol";
import "./api/IStaking.sol";

/// @title Sortition Pool Factory
/// @notice Factory for the creation of new sortition pools.
contract SortitionPoolFactory {
    /// @notice Creates a new sortition pool instance.
    /// @return Address of the new sortition pool contract instance.
    function createSortitionPool(
        IStaking stakingContract
    ) public returns (address) {
        uint256 minimumStake = stakingContract.minimumStake();
        return address(
            new SortitionPool(
                stakingContract,
                minimumStake,
                msg.sender
            )
        );
    }
}
