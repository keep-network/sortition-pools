pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import './StackLib.sol';
import './Branch.sol';
import './Position.sol';
import './Trunk.sol';

contract Sortition {
    using StackLib for uint256[];
    using Branch for uint;
    using Position for uint;
    using Trunk for uint;

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

    // the leaf after the rightmost occupied leaf of each stack
    uint[16] rightmostLeaf;
    // the empty leaves in each stack
    // between 0 and the rightmost occupied leaf
    uint256[][16] emptyLeaves;

    function leavesInStack(uint trunkN) public view returns (bool) {
      return emptyLeaves[trunkN].getSize() > 0;
    }

    function leavesToRight(uint trunkN) public view returns (bool) {
      return rightmostLeaf[trunkN] <= trunkN.lastLeaf();
    }

    function hasSpace(uint trunkN) public view returns (bool) {
      return leavesInStack(trunkN) || leavesToRight(trunkN);
    }

    function getEmptyLeaf(uint trunkN) public returns (uint) {
      require(hasSpace(trunkN), "Trunk is full");
      if (leavesInStack(trunkN)) {
        return emptyLeaves[trunkN].stackPop();
      } else {
        uint newLeaf = rightmostLeaf[trunkN];
        rightmostLeaf[trunkN] = newLeaf + 1;
        return newLeaf;
      }
    }

    function fitsUnderCap(uint16 addedWeight, uint trunkN) public view returns (bool) {
      uint16 currentWeight = root.getSlot(trunkN);
      uint sumWeight = uint(currentWeight) + uint(addedWeight);
      return sumWeight < 65536;
    }

    function suitableTrunk(uint16 addedWeight) public view returns (uint) {
      uint theTrunk = 0;
      bool selected = false;
      while (!selected) {
        bool weightOkay = fitsUnderCap(addedWeight, theTrunk);
        bool spaceOkay = hasSpace(theTrunk);
        if (weightOkay && spaceOkay) {
          selected = true;
        } else {
          theTrunk += 1;
        }
      }
      return theTrunk;
    }

    function insert(address operator, uint16 weight) public {
      uint theTrunk = suitableTrunk(weight);
      uint position = getEmptyLeaf(theTrunk);
      setLeaf(position, operator, weight);
    }

    function setLeaf(uint leafPosition, address op, uint16 leafWeight) public {
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
      root = root.setSlot(childSlot, nodeWeight);
    }

    function getRoot() public view returns (uint){
      return root;
    }

   constructor() public {
        owner = msg.sender;

        for (uint i = 0; i < 16; i++) {
          rightmostLeaf[i] = i.firstLeaf();
        }
    }
    function getOwner() public view returns (address){
        return owner;
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
