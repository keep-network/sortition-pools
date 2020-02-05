pragma solidity ^0.5.10;

contract BondingContractStub {
    function availableUnbondedValue(
        address operator,
        address bondCreator,
        address additionalAuthorizedContract
    ) external returns (uint256) {
        return 20000;
    }
}
