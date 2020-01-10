pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import './StackLib.sol';
import './Branch.sol';
import './Position.sol';
import './Trunk.sol';
import './Leaf.sol';

contract Sortition {
    using StackLib for uint256[];
    using Branch for uint;
    using Position for uint;
    using Trunk for uint;
    using Leaf for uint;

    // implicit tree
    uint root;
    mapping(uint => mapping(uint => uint)) branches;
    mapping(uint => uint) leaves;

    // the leaf after the rightmost occupied leaf of each stack
    uint[16] rightmostLeaf;
    // the empty leaves in each stack
    // between 0 and the rightmost occupied leaf
    uint256[][16] emptyLeaves;

    function leavesInStack(uint trunkN) internal view returns (bool) {
      return emptyLeaves[trunkN].getSize() > 0;
    }

    function leavesToRight(uint trunkN) internal view returns (bool) {
      return rightmostLeaf[trunkN] <= trunkN.lastLeaf();
    }

    function hasSpace(uint trunkN) internal view returns (bool) {
      return leavesInStack(trunkN) || leavesToRight(trunkN);
    }

    function getEmptyLeaf(uint trunkN) internal returns (uint) {
      require(hasSpace(trunkN), "Trunk is full");
      if (leavesInStack(trunkN)) {
        return emptyLeaves[trunkN].stackPop();
      } else {
        uint newLeafPosition = rightmostLeaf[trunkN];
        rightmostLeaf[trunkN] = newLeafPosition + 1;
        return newLeafPosition;
      }
    }

    function fitsUnderCap(uint16 addedWeight, uint trunkN) internal view returns (bool) {
      uint16 currentWeight = root.getSlot(trunkN);
      uint sumWeight = uint(currentWeight) + uint(addedWeight);
      return sumWeight < 65536;
    }

    function suitableTrunk(uint16 addedWeight) internal view returns (uint) {
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
      uint theLeaf = Leaf.make(operator, weight);
      setLeaf(position, theLeaf);
    }

    function toLeaf(address operator, uint16 weight) public view returns (uint) {
      return Leaf.make(operator, weight);
    }

    function getLeaf(uint position) public view returns (uint) {
      return leaves[position];
    }

    function removeLeaf(uint position) public {
      uint trunkN = position.trunk();
      uint rightmostSubOne = rightmostLeaf[trunkN] - 1;
      bool isRightmost = position == rightmostSubOne;

      setLeaf(position, 0);

      if (isRightmost) {
        rightmostLeaf[trunkN] = rightmostSubOne;
      } else {
        emptyLeaves[trunkN].stackPush(position);
      }
    }

    function updateLeaf(uint position, uint16 weight) public {
      address leafOperator = getLeaf(position).operator();
      uint newLeaf = Leaf.make(leafOperator, weight);
      setLeaf(position, newLeaf);
    }

    function setLeaf(uint leafPosition, uint theLeaf) public {
      uint childSlot;
      uint treePosition = leafPosition;
      uint treeNode;
      uint newNode;
      uint16 nodeWeight = theLeaf.weight();

      // set leaf
      leaves[leafPosition] = theLeaf;

      // set levels 5 to 2
      for (uint level = 5; level >= 2; level--) {
        childSlot = treePosition.slot();
        treePosition = treePosition.parent();
        treeNode = branches[level][treePosition];
        newNode = treeNode.setSlot(childSlot, nodeWeight);
        branches[level][treePosition] = newNode;
        nodeWeight = uint16(newNode.sumWeight());
      }

      // set level Root
      childSlot = treePosition.slot();
      root = root.setSlot(childSlot, nodeWeight);
    }

    function getRoot() public view returns (uint){
      return root;
    }

    function totalWeight() internal view returns (uint){
      return root.sumWeight();
    }

    function pickWeightedLeaf(uint index) public returns (uint) {
      require(index < totalWeight(), "Index greater than total weight");

      uint currentIndex = index;
      uint currentNode = root;
      uint currentPosition = 0;
      uint currentSlot;

      // get root slot
      (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);

      // get slots from levels 2 to 5
      for (uint level = 2; level <= 5; level++) {
        currentPosition = currentPosition.child(currentSlot);
        currentNode = branches[level][currentPosition];
        (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);
      }

      // get leaf
      uint leafPosition = currentPosition.child(currentSlot);

      return leafPosition;
    }

    function leafAddress(uint leaf) public view returns (address) {
      return leaf.operator();
    }

   constructor() public {
        for (uint i = 0; i < 16; i++) {
          rightmostLeaf[i] = i.firstLeaf();
        }
    }
}
