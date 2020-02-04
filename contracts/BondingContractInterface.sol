pragma solidity ^0.5.10;

interface BondingContract {
    // Gives the amount of ETH
    // the `operator` has made available for bonding by the `bondCreator`.
    // If the operator doesn't exist,
    // or the bond creator isn't authorized,
    // returns 0.
    function availableUnbondedValue(
        address operator,
        address bondCreator
    )
        external
        view
        returns (uint256);
}
