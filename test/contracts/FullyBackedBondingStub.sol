pragma solidity 0.5.17;

import "../../contracts/api/IFullyBackedBonding.sol";
import "./BondingContractStub.sol";

contract FullyBackedBondingStub is IFullyBackedBonding, BondingContractStub {
  mapping(address => bool) initialized;

  function setInitialized(address operator, bool value) public {
    initialized[operator] = value;
  }

  function isInitialized(
    address operator,
    address // bondCreator
  ) public view returns (bool) {
    return initialized[operator];
  }
}
