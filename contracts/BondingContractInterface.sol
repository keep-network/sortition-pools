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
    ) external view returns (uint256);

    // Create a bond, throwing an exception on failure
    function createBond(
        address operator,
        address holder,
        uint256 referenceID,
        uint256 amount
    ) external;

    // Reassign a bond, throwing an exception on failure
    function reassignBond(
        address operator,
        uint256 referenceID,
        address newHolder,
        uint256 newReferenceID
    ) external;
}
