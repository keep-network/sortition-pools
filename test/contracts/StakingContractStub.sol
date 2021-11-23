pragma solidity 0.8.6;

contract StakingContractStub {
    mapping(address => uint256) public stakedTokens;

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

    function rolesOf(address operator)
        public
        view
        returns (address, address, address)
    {
        return (operator, operator, operator);
    }
}
