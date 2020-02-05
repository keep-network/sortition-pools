pragma solidity ^0.5.10;

interface ISortitionPool {
    function selectGroup(uint256 groupSize, bytes32 seed)
        public returns (address[] memory selected);

    function isOperatorInPool(address operator) public view returns (bool);
    function isOperatorUpToDate(address operator) public view returns (bool);

    function joinPool(address operator) public;
    function updateOperatorWeight(address operator) public;
    function updateOperatorStatus(address operator) public;
}
