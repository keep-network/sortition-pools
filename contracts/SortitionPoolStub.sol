pragma solidity 0.8.6;

import "./SortitionPool.sol";

contract SortitionPoolStub is SortitionPool {
  constructor(uint256 _poolWeightDivisor) SortitionPool(_poolWeightDivisor) {}

  function nonViewSelectGroup(uint256 groupSize, bytes32 seed)
    public
    returns (uint32[] memory)
  {
    return selectGroup(groupSize, seed);
  }
}
