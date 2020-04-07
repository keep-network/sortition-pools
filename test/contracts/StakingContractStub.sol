pragma solidity ^0.5.10;

contract StakingContractStub {
    mapping(address => uint256) internal stakedTokens;
    uint256 internal minStake;

    function eligibleStake(
        address operator,
        address // operatorContract
    )
        external view returns (uint256)
    {
        return stakedTokens[operator];
    }

    function minimumStake() external view returns (uint256) {
        return minStake;
    }

    function setStake(address operator, uint256 stake) public {
        stakedTokens[operator] = stake;
    }

    function setMinimumStake(uint256 stake) public {
        minStake = stake;
    }
}
