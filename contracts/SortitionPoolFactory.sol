pragma solidity ^0.5.10;

import "./SortitionPool.sol";

/// @title Sortition Pool Factory
/// @notice Factory for the creation of new sortition pools.
contract SortitionPoolFactory {

    StakingContract staking;
    uint256 minimumStake;

    function setParams(address stakingContract, uint256 minStake) public {
      staking = StakingContract(stakingContract);
      minimumStake = minStake;
    }

    /// @notice Creates a new sortition pool instance.
    /// @return Address of the new sortition pool contract instance.
    function createSortitionPool() public returns(address) {
        return address(new SortitionPool(staking, minimumStake));
    }
}
