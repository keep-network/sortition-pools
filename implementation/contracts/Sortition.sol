pragma solidity ^0.5.10;

struct Leaf {
    uint16 weight;
    address operator;
}

contract Sortition {
    address public owner;

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
    unit[][16] hasSpace5;

   constructor() public {
        owner = msg.sender;
    }
    function getOwner() public view returns (address){
        return owner;
    }

    function insert(address operator, uint16 weight) public returns (bool){
      
    }

    function select(uint seed) public returns (address){
      
    }

    function update(uint location, Leaf operatorInfo) {
      
    }

    function remove(uint location) {
      
    }

}
