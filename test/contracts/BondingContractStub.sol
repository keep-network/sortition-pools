// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../../contracts/api/IBonding.sol";

contract BondingContractStub is IBonding {
  mapping(address => uint256) public unbondedValue;

  function setBondableValue(address operator, uint256 value) public {
    unbondedValue[operator] = value;
  }

  function availableUnbondedValue(
    address operator,
    address, // bondCreator,
    address // additionalAuthorizedContract
  ) external view override returns (uint256) {
    return unbondedValue[operator];
  }
}
