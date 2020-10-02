pragma solidity 0.5.17;

contract BondingContractStub {
  mapping(address => uint256) public unbondedValue;

  function availableUnbondedValue(
    address operator,
    address, // bondCreator,
    address // additionalAuthorizedContract
  ) external view returns (uint256) {
    return unbondedValue[operator];
  }

  function setBondableValue(address operator, uint256 value) public {
    unbondedValue[operator] = value;
  }
}
