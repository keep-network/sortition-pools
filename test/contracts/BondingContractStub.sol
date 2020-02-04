pragma solidity ^0.5.10;

contract BondingContractStub {
    function availableUnbondedValue(
        address operator,
        address bondCreator
    ) external returns (uint256) {
        return 20000;
    }

    function createBond(
        address operator,
        address holder,
        uint256 referenceID,
        uint256 amount
    ) external {
        assert(true);
    }

    function reassignBond(
        address operator,
        uint256 referenceID,
        address newHolder,
        uint256 newReferenceID
    ) external {
        assert(true);
    }
}
