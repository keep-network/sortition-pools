pragma solidity ^0.5.10;

contract Sortition {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    function getOwner() public view returns (address){
        return owner;
    }
}
