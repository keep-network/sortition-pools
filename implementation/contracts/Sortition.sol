pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import './StackLib.sol';

contract Sortition {
    using StackLib for uint256[];

    address public owner;

    struct Leaf {
        uint16 weight;
        address operator;
    }

    // implicit tree
    uint root;
    uint[16] level2;
    uint[256] level3;
    uint[4096] level4;
    uint[65536] level5;
    Leaf[1048576] leaves;

    // storing nodes with empty children within the specified trunk,
    // on the specified level
    //
    // hasSpace2[trunkN]
    uint[][16] hasSpace2;
    uint[][16] hasSpace3;
    uint[][16] hasSpace4;
    uint[][16] hasSpace5;

   constructor() public {
        owner = msg.sender;
    }
    function getOwner() public view returns (address){
        return owner;
    }

    function insert(address operator, uint16 weight) public returns (bool){
      return true;
    }

    function select(uint seed) public returns (address){
      return address(0);
    }

    function update(uint location, Leaf memory operatorInfo) public returns (bool){
        return true;

    }

    function remove(uint location) public returns (bool){
        return true;

    }

}
