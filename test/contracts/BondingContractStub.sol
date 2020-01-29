pragma solidity ^0.5.10;

contract BondingContractStub {
    function isEligible(
        address operator,
        uint stakingWeight,
        uint bondSize
    ) external returns (bool) {
        return true;
    }
}