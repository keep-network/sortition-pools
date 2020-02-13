pragma solidity ^0.5.10;

contract StakingContractStub {
    mapping(address => uint256) stakedTokens;

    function eligibleStake(
        address operator,
        address // operatorContract
    )
        external view returns (uint256)
    {
        return stakedTokens[operator];
    }

    function setStake(address operator, uint256 stake) public {
        stakedTokens[operator] = stake;
    }
}
