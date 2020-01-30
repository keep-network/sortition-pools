pragma solidity ^0.5.10;

contract BondingContractStub {
  mapping(address => uint) eligibleWeight;

    function isEligible(
        address operator,
        uint stakingWeight,
        uint bondSize
    ) external returns (bool) {
        return eligibleWeight[operator] >= stakingWeight;
    }

    function setWeight(address operator, uint stakingWeight) public {
      eligibleWeight[operator] = stakingWeight;
    }
}
