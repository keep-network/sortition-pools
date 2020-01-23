pragma solidity ^0.5.10;

import "./CloneFactory.sol";
import "../SortitionPool.sol";

/// @title Sortition Pool Factory
/// @notice Factory for the creation of new sortition pools.
/// @dev We avoid redeployment of sortition pool contract by using the clone factory.
/// Proxy delegates calls to sortition pool and therefore does not affect contract's
/// state. This means that we only need to deploy the sortition pool contract once.
/// The factory provides clean state for every new sortition pool clone.
contract SortitionPoolFactory is CloneFactory{

    // Holds the address of the sortition pool contract which will be used as a
    // master contract for cloning.
    address public masterSortitionPoolAddress;

    event SortitionPoolCloneCreated(address cloneAddress);

    /// @notice Set the master sortition pool contract address on contract
    /// initialization.
    /// @param _masterSortitionPoolAddress  The address of the master sortition
    /// pool contract.
    constructor(address _masterSortitionPoolAddress) public {
        masterSortitionPoolAddress = _masterSortitionPoolAddress;
    }

    /// @notice Creates a new sortition pool instance.
    /// @return Address of the new sortition pool contract instance.
    function createSortitionPool() public payable returns(address cloneAddress) {
        cloneAddress = createClone(masterSortitionPoolAddress);

        emit SortitionPoolCloneCreated(cloneAddress);
    }
}
