pragma solidity 0.8.6;

/// @title Rewards
/// @notice Rewards are allocated proportionally to operators
/// present in the pool at payout based on their weight in the pool.
///
/// To facilitate this, we use a global accumulator value
/// to track the total rewards one unit of weight would've earned
/// since the creation of the pool.
///
/// Whenever a reward is paid, the accumulator is increased
/// by the size of the reward divided by the total weight
/// of all eligible operators in the pool.
///
/// Each operator has an individual accumulator value,
/// set to equal the global accumulator when the operator joins the pool.
/// This accumulator reflects the amount of rewards
/// that have already been accounted for with that operator.
///
/// Whenever an operator's weight in the pool changes,
/// we can update the amount of rewards the operator has earned
/// by subtracting the operator's accumulator from the global accumulator.
/// This gives us the amount of rewards one unit of weight has earned
/// since the last time the operator's rewards have been updated.
/// Then we multiply that by the operator's previous (pre-change) weight
/// to determine how much rewards in total the operator has earned,
/// and add this to the operator's earned rewards.
/// Finally, we set the operator's accumulator to the global accumulator value.
contract Rewards {
  struct OperatorRewards {
    // The state of the global accumulator
    // when the operator's rewards were last updated
    uint96 accumulated;
    // The amount of rewards collected by the operator after the latest update.
    // The amount the operator could withdraw may equal `available`
    // or it may be greater, if more rewards have been paid in since then.
    uint96 available;
    // If nonzero, the operator is ineligible for rewards
    // and may only re-enable rewards after the specified timestamp.
    // XXX: unsigned 32-bit integer unix seconds, will break around 2106
    uint32 ineligibleUntil;
    // Locally cached weight of the operator,
    // used to reduce the cost of setting operators ineligible.
    uint32 weight;
  }

  // The global accumulator of how much rewards
  // a hypothetical operator of weight 1 would have earned
  // since the creation of the pool.
  uint96 internal globalRewardAccumulator;
  // If the amount of reward tokens paid in
  // does not divide cleanly by pool weight,
  // the difference is recorded as rounding dust
  // and added to the next reward.
  uint96 internal rewardRoundingDust;
  // The total weight of all operators in the pool
  // who are ineligible for rewards.
  uint32 internal totalIneligibleWeight;

  mapping(address => OperatorRewards) internal operatorRewards;

  /// @notice Internal function for updating the global state of rewards.
  function addRewards(uint96 rewardAmount, uint32 currentPoolWeight) internal {
    require(currentPoolWeight >= 0, "No recipients in pool");

    uint96 rewardWeight = uint96(currentPoolWeight - totalIneligibleWeight);

    uint96 totalAmount = rewardAmount + rewardRoundingDust;
    uint96 perWeightReward = totalAmount / rewardWeight;
    uint96 newRoundingDust = totalAmount % rewardWeight;

    globalRewardAccumulator += perWeightReward;
    rewardRoundingDust = newRoundingDust;
  }

  /// @notice Internal function for updating the operator's reward state.
  function updateOperatorRewards(address operator, uint32 newWeight) internal {
    uint96 acc = globalRewardAccumulator;
    OperatorRewards memory o = operatorRewards[operator];
    if (o.ineligibleUntil == 0) {
      // If operator is not ineligible, update their earned rewards
      uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
      o.available += accruedRewards;
    } else {
      // If ineligible, update total ineligible weight
      uint32 iWeight = totalIneligibleWeight;
      iWeight -= o.weight;
      iWeight += newWeight;
      totalIneligibleWeight = iWeight;
    }
    // In any case, update their accumulator and weight
    o.accumulated = acc;
    o.weight = newWeight;
    operatorRewards[operator] = o;
  }

  /// @notice Set the amount of withdrawable tokens to zero
  /// and return the previous withdrawable amount.
  /// @dev Does not update the withdrawable amount,
  /// but should usually be accompanied by an update.
  function withdrawOperatorRewards(address operator)
    internal
    returns (uint96 withdrawable)
  {
    OperatorRewards storage o = operatorRewards[operator];
    withdrawable = o.available;
    o.available = 0;
  }

  function setIneligible(address[] memory operators, uint32 until) internal {
    OperatorRewards memory o = OperatorRewards(0, 0, 0, 0);
    uint96 globalAcc = globalRewardAccumulator;
    uint96 accrued = 0;
    uint256 ineligibleWeightSum = 0;

    for (uint256 i = 0; i < operators.length; i++) {
      address operator = operators[i];
      OperatorRewards storage r = operatorRewards[operator];
      o.available = r.available;
      o.accumulated = r.accumulated;
      o.ineligibleUntil = r.ineligibleUntil;
      o.weight = r.weight;

      if (o.ineligibleUntil != 0) {
        // If operator is already ineligible,
        // don't earn rewards or shorten its ineligibility
        if (o.ineligibleUntil < until) {
          o.ineligibleUntil = until;
        }
      } else {
        // The operator becomes ineligible -> earn rewards
        o.ineligibleUntil = until;
        accrued = (globalAcc - o.accumulated) * uint96(o.weight);
        o.available += accrued;
        ineligibleWeightSum += uint256(o.weight);
      }
      o.accumulated = globalAcc;

      r.available = o.available;
      r.accumulated = o.accumulated;
      r.ineligibleUntil = o.ineligibleUntil;
      r.weight = o.weight;
    }
    totalIneligibleWeight += uint32(ineligibleWeightSum);
  }

  function restoreEligibility(address operator) internal {
    OperatorRewards memory o = operatorRewards[operator];
    // solhint-disable-next-line not-rely-on-time
    require(o.ineligibleUntil <= block.timestamp, "Operator still ineligible");
    uint96 acc = globalRewardAccumulator;
    o.accumulated = acc;
    o.ineligibleUntil = 0;
    totalIneligibleWeight -= o.weight;
    operatorRewards[operator] = o;
  }

  /// @notice Calculate the amount of tokens the operator could withdraw now
  /// if its current weight is `oldWeight`.
  /// Does not update state, but returns what the results would be.
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
