pragma solidity ^0.5.10;

contract GasStation {
  uint constant GAS_DEPOSIT_SIZE = 5;

  mapping(address => mapping(uint => uint)) gasDeposits;

  function depositGas(address addr) internal {
    setDeposit(addr, 1);
  }

  function releaseGas(address addr) internal {
    setDeposit(addr, 0);
  }

  function setDeposit(address addr, uint val) internal {
    for (uint i = 0; i < GAS_DEPOSIT_SIZE; i++) {
      gasDeposits[addr][i] = val;
    }
  }
}
