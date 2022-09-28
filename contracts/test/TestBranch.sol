pragma solidity 0.8.17;

import "../Branch.sol";

contract TestBranch {
  using Branch for *;

  uint256 private node =
    0x7777777766666666555555554444444433333333222222221111111100000000;

  function runPickWeightedSlotTest() public {
    uint256[3] memory weights = [uint256(0), 1, 0x11111222];
    uint256[3] memory indices = [uint256(1), 1, 2];
    uint256[3] memory surpluses = [uint256(0), 1, 0x111];
    uint256 index;
    uint256 surplus;
    for (uint256 i = 0; i < 3; i++) {
      (index, surplus) = node.pickWeightedSlot(weights[i]);
      require(index == indices[i], "pickWeightedSlot() index incorrect");
      require(surplus == surpluses[i], "pickWeightedSlot() surplus incorrect");
    }
  }
}
