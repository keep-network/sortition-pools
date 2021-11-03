pragma solidity 0.8.6;

import '../../contracts/Rewards.sol';

contract RewardsStub is Rewards {
    address[] internal operators;
    mapping(address => uint256) internal operatorWeight;
    mapping(address => uint256) internal withdrawnRewards;

    function addOperator(address operator, uint256 weight) public {
        operators.push(operator);
        operatorWeight[operator] = weight;
        operatorRewards[operator].accumulated = globalRewardAccumulator;
    }

    function syncRewards(address operator) public {
        updateOperatorRewards(operator, operatorWeight[operator]);
    }

    function updateOperatorWeight(address operator, uint256 newWeight) public {
        updateOperatorRewards(operator, operatorWeight[operator]);
        operatorWeight[operator] = newWeight;
    }

    function payReward(uint256 rewardAmount) public {
        addRewards(uint96(rewardAmount), getPoolWeight());
    }

    function withdrawRewards(address operator) public {
        syncRewards(operator);
        withdrawnRewards[operator] += uint256(withdrawOperatorRewards(operator));
    }

    function getWithdrawnRewards(address operator) public view returns (uint256) {
        return withdrawnRewards[operator];
    }

    function getPoolWeight() public view returns (uint256 poolWeight) {
        for (uint256 i = 0; i < operators.length; i++) {
            poolWeight += operatorWeight[operators[i]];
        }
        return poolWeight;
    }

    function getAccumulator(address operator) public view returns (uint256) {
        return uint256(operatorRewards[operator].accumulated);
    }

    function getAccruedRewards(address operator) public view returns (uint256) {
        return uint256(operatorRewards[operator].available);
    }

    function getAvailableRewards(address operator) public view returns (uint256) {
        return uint256(availableRewards(operator, operatorWeight[operator]));
    }

    function getGlobalAccumulator() public view returns (uint256) {
        return uint256(globalRewardAccumulator);
    }

    function getRoundingDust() public view returns (uint256) {
        return uint256(rewardRoundingDust);
    }
}
