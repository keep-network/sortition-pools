pragma solidity 0.8.9;

contract StakingContractStub {
    function rolesOf(address operator)
        public
        view
        returns (address, address, address)
    {
        return (operator, operator, operator);
    }
}
