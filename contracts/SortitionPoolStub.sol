pragma solidity 0.8.6;

import "./SortitionPool.sol";

contract SortitionPoolStub is SortitionPool {
  constructor(
    IStaking _stakingContract,
    uint256 _minimumStake,
    uint256 _poolWeightDivisor,
    address _poolOwner
  )
    SortitionPool(
      _stakingContract,
      _minimumStake,
      _poolWeightDivisor,
      _poolOwner
    )
  {}

  function nonViewSelectGroup(uint256 groupSize, bytes32 seed)
    public
    returns (address[] memory)
  {
    return selectGroup(groupSize, seed);
  }
}