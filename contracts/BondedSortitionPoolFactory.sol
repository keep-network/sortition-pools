pragma solidity ^0.5.10;

import "./BondedSortitionPool.sol";
import "./BondingContractInterface.sol";
import "./StakingContractInterface.sol";

/// @title Bonded Sortition Pool Factory
/// @notice Factory for the creation of new bonded sortition pools.
contract BondedSortitionPoolFactory {

    /// @notice Creates a new bonded sortition pool instance.
    /// @return Address of the new bonded sortition pool contract instance.
    function createSortitionPool(
        StakingContract stakingContract,
        BondingContract bondingContract,
        uint256 minimumStake
    ) public returns (address) {
        return address(
            new BondedSortitionPool(
                stakingContract,
                bondingContract,
                minimumStake
            )
        );
    }
}
