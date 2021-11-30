pragma solidity 0.8.6;

import "../../contracts/Rewards.sol";

contract RewardsStub is Rewards {
    address[] internal operators;
    mapping(address => uint256) internal operatorWeight;
    mapping(address => uint256) internal withdrawnRewards;

    function addOperator(address operator, uint256 weight) public {
        operators.push(operator);
        operatorWeight[operator] = weight;
        operatorRewards[operator].accumulated = globalRewardAccumulator;
        updateOperatorRewards(operator, uint32(weight));
    }

    function syncRewards(address operator) public {
        updateOperatorRewards(operator, uint32(operatorWeight[operator]));
    }

    function updateOperatorWeight(address operator, uint256 newWeight) public {
        updateOperatorRewards(operator, uint32(newWeight));
        operatorWeight[operator] = newWeight;
    }

    function payReward(uint256 rewardAmount) public {
        addRewards(uint96(rewardAmount), uint32(getPoolWeight()));
    }

    function withdrawRewards(address operator) public {
        syncRewards(operator);
        withdrawnRewards[operator] += uint256(withdrawOperatorRewards(operator));
    }

    function makeIneligible(address operator, uint256 duration) public {
        address[] memory _operators = new address[](1);
        _operators[0] = operator;
        // solhint-disable-next-line not-rely-on-time
        setIneligible(_operators, block.timestamp + duration);
    }

    function massMakeIneligible(address[] memory _operators, uint256 duration) public {
        // solhint-disable-next-line not-rely-on-time
        setIneligible(_operators, block.timestamp + duration);
    }

    function makeEligible(address operator) public {
        restoreEligibility(operator);
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

    function getIneligibleWeight() public view returns (uint256) {
        return uint256(totalIneligibleWeight);
    }
}
