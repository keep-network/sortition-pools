pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import './StackLib.sol';
import './Branch.sol';
import './Position.sol';

contract Sortition {
    using StackLib for uint256[];
    using Branch for uint;
    using Position for uint;

    address public owner;

    struct Leaf {
        uint16 weight;
        address operator;
    }

    // implicit tree
    uint public root;
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

    function setLeaf(uint leafPosition, address op, uint16 leafWeight) public returns (uint){
      Leaf memory theLeaf = Leaf({operator: op, weight: leafWeight});

      // set leaf
      leaves[leafPosition] = theLeaf;

      // set level 5
      uint childSlot = leafPosition.slot();
      uint treePosition = leafPosition.parent();
      uint treeNode = level5[treePosition];
      uint newNode = treeNode.setSlot(childSlot, leafWeight);
      level5[treePosition] = newNode;
      uint16 nodeWeight = uint16(newNode.sumWeight());

      uint node5 = newNode;

      // set level 4
      childSlot = treePosition.slot();
      treePosition = treePosition.parent();
      treeNode = level4[treePosition];
      newNode = treeNode.setSlot(childSlot, nodeWeight);
      level4[treePosition] = newNode;
      nodeWeight = uint16(newNode.sumWeight());

      uint node4 = newNode;

      // set level 3
      childSlot = treePosition.slot();
      treePosition = treePosition.parent();
      treeNode = level3[treePosition];
      newNode = treeNode.setSlot(childSlot, nodeWeight);
      level3[treePosition] = newNode;
      nodeWeight = uint16(newNode.sumWeight());

      uint node3 = newNode;

      // set level 2
      childSlot = treePosition.slot();
      treePosition = treePosition.parent();
      treeNode = level2[treePosition];
      newNode = treeNode.setSlot(childSlot, nodeWeight);
      level2[treePosition] = newNode;
      nodeWeight = uint16(newNode.sumWeight());

      uint node2 = newNode;

      // set level Root
      childSlot = treePosition.slot();
      /* uint storage oldRoot = root; */
      root = root.setSlot(childSlot, nodeWeight);
      /* oldRoot = newRoot; */

      return root;
    }

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
