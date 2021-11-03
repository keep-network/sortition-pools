pragma solidity 0.8.6;

contract Rewards {
  struct OperatorRewards {
    uint96 accumulated;
    uint96 available;
  }

  uint96 internal globalRewardAccumulator;
  uint96 internal rewardRoundingDust;

  mapping(address => OperatorRewards) internal operatorRewards;

  function addRewards(uint96 rewardAmount, uint256 currentPoolWeight) internal {
    require(currentPoolWeight >= 0, "No recipients in pool");

    uint96 totalAmount = rewardAmount + rewardRoundingDust;
    uint96 perWeightReward = totalAmount / uint96(currentPoolWeight);
    uint96 newRoundingDust = totalAmount % uint96(currentPoolWeight);

    globalRewardAccumulator += perWeightReward;
    rewardRoundingDust = newRoundingDust;
  }

  function updateOperatorRewards(address operator, uint256 oldWeight) internal {
    uint96 acc = globalRewardAccumulator;
    OperatorRewards storage o = operatorRewards[operator];
    uint96 accruedRewards = (acc - o.accumulated) * uint96(oldWeight);
    o.available += accruedRewards;
    o.accumulated = acc;
  }

  function withdrawOperatorRewards(address operator)
    internal
    returns (uint96 withdrawable)
  {
    OperatorRewards storage o = operatorRewards[operator];
    withdrawable = o.available;
    o.available = 0;
  }

  function availableRewards(address operator, uint256 oldWeight)
    internal
    view
    returns (uint96 available)
  {
    uint96 acc = globalRewardAccumulator;
    OperatorRewards storage o = operatorRewards[operator];
    uint96 accruedRewards = (acc - o.accumulated) * uint96(oldWeight);
    uint96 previousAvailableRewards = o.available;
    return accruedRewards + previousAvailableRewards;
  }
}
