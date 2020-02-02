pragma solidity ^0.5.10;

contract GasStation {
    uint256 constant GAS_DEPOSIT_SIZE = 0;

    mapping(address => mapping(uint256 => uint256)) gasDeposits;

    function depositGas(address addr) internal {
        setDeposit(addr, 1);
    }

    function releaseGas(address addr) internal {
        setDeposit(addr, 0);
    }

    function setDeposit(address addr, uint256 val) internal {
        for (uint256 i = 0; i < GAS_DEPOSIT_SIZE; i++) {
            gasDeposits[addr][i] = val;
        }
    }
}
