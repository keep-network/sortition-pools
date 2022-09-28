pragma solidity 0.8.17;

import "../../contracts/Rewards.sol";

contract RewardsStub is Rewards {
    uint32[] internal operators;
    mapping(uint32 => uint256) internal operatorWeight;
    mapping(uint32 => uint256) internal withdrawnRewards;
    uint256 internal ineligibleRewards;

    function addOperator(uint32 operator, uint256 weight) public {
        operators.push(operator);
        operatorWeight[operator] = weight;
        updateOperatorRewards(operator, uint32(weight));
    }

    function updateOperatorWeight(uint32 operator, uint256 newWeight) public {
        updateOperatorRewards(operator, uint32(newWeight));
        operatorWeight[operator] = newWeight;
    }

    function payReward(uint256 rewardAmount) public {
        addRewards(uint96(rewardAmount), uint32(getPoolWeight()));
    }

    function withdrawRewards(uint32 operator) public {
        updateOperatorRewards(operator, uint32(operatorWeight[operator]));
        withdrawnRewards[operator] += uint256(withdrawOperatorRewards(operator));
    }

    function withdrawIneligible() public {
        ineligibleRewards += uint256(withdrawIneligibleRewards());
    }

    function makeIneligible(uint32 operator, uint256 duration) public {
        uint32[] memory _operators = new uint32[](1);
        _operators[0] = operator;
        // solhint-disable-next-line not-rely-on-time
        setIneligible(_operators, block.timestamp + duration);
    }

    function massMakeIneligible(uint32[] memory _operators, uint256 duration) public {
        // solhint-disable-next-line not-rely-on-time
        setIneligible(_operators, block.timestamp + duration);
    }

    function makeEligible(uint32 operator) public {
        restoreEligibility(operator);
    }

    function getAvailableRewards(uint32 operator) public view returns (uint96) {
      return availableRewards(operator);
    }

    function getWithdrawnRewards(uint32 operator) public view returns (uint256) {
        return withdrawnRewards[operator];
    }

    function getPoolWeight() public view returns (uint256 poolWeight) {
        for (uint256 i = 0; i < operators.length; i++) {
            poolWeight += operatorWeight[operators[i]];
        }
        return poolWeight;
    }

    function getAccumulator(uint32 operator) public view returns (uint256) {
        return uint256(operatorRewards[operator].accumulated);
    }

    function getAccruedRewards(uint32 operator) public view returns (uint256) {
        return uint256(operatorRewards[operator].available);
    }

    function getGlobalAccumulator() public view returns (uint256) {
        return uint256(globalRewardAccumulator);
    }

    function getRoundingDust() public view returns (uint256) {
        return uint256(rewardRoundingDust);
    }

    function getIneligibleRewards() public view returns (uint256) {
        return ineligibleRewards;
    }
}
