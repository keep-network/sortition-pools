pragma solidity ^0.5.10;

import "./FullyBackedSortitionPool.sol";
import "./api/IBonding.sol";
import "./api/IStaking.sol";

/// @title Fully-Backed Sortition Pool Factory
/// @notice Factory for the creation of fully-backed sortition pools.
contract FullyBackedSortitionPoolFactory {

    /// @notice Creates a new fully-backed sortition pool instance.
    /// @param bondingContract Keep Bonding contract reference.
    /// @param minimumStake Minimum stake value making the operator eligible to
    /// join the network.
    /// @param bondWeightDivisor Constant divisor for the available bond used to 
    /// evalate the applicable weight.
    /// @return Address of the new fully-backed sortition pool contract instance.
    function createSortitionPool(
        IBonding bondingContract,
        uint256 minimumStake,
        uint256 bondWeightDivisor
    ) public returns (address) {
        return address(
            new FullyBackedSortitionPool(
                bondingContract,
                minimumStake,
                bondWeightDivisor,
                msg.sender
            )
        );
    }
}
