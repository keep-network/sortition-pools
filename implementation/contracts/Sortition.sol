pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import './StackLib.sol';
import './Branch.sol';
import './Position.sol';
import './Trunk.sol';
import './Leaf.sol';

contract Sortition is Position, Branch, Trunk, Leaf {
  using StackLib for uint256[];

    address public owner;

    // implicit tree
    uint root;
    uint[16] level2;
    uint[256] level3;
    uint[4096] level4;
    uint[65536] level5;
    uint[1048576] leaves;

    // the leaf after the rightmost occupied leaf of each stack
    uint[16] rightmostLeaf;
    // the empty leaves in each stack
    // between 0 and the rightmost occupied leaf
    uint256[][16] emptyLeaves;

    function leavesInStack(uint trunkN) public view returns (bool) {
      return StackLib.getSize(emptyLeaves[trunkN]) > 0;
    }

    function leavesToRight(uint trunkN) public view returns (bool) {
      return rightmostLeaf[trunkN] <= lastLeaf(trunkN);
    }

    function hasSpace(uint trunkN) public view returns (bool) {
      return leavesInStack(trunkN) || leavesToRight(trunkN);
    }

    function getEmptyLeaf(uint trunkN) public returns (uint) {
      require(hasSpace(trunkN), "Trunk is full");
      if (leavesInStack(trunkN)) {
        return StackLib.stackPop(emptyLeaves[trunkN]);
      } else {
        uint newLeafPosition = rightmostLeaf[trunkN];
        rightmostLeaf[trunkN] = newLeafPosition + 1;
        return newLeafPosition;
      }
    }

    function fitsUnderCap(uint16 addedWeight, uint trunkN) public view returns (bool) {
      uint16 currentWeight = getSlot(root, trunkN);
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
      uint theLeaf = makeLeaf(operator, weight);
      setLeaf(position, theLeaf);
    }

    function toLeaf(address operator, uint16 weight) public view returns (uint) {
      return makeLeaf(operator, weight);
    }

    function getLeaf(uint position) public view returns (uint) {
      return leaves[position];
    }

    function removeLeaf(uint position) public {
      uint trunkN = trunk(position);
      uint rightmostSubOne = rightmostLeaf[trunkN] - 1;
      bool isRightmost = position == rightmostSubOne;

      setLeaf(position, 0);

      if (isRightmost) {
        rightmostLeaf[trunkN] = rightmostSubOne;
      } else {
        StackLib.stackPush(emptyLeaves[trunkN], position);
      }
    }

    function updateLeaf(uint position, uint16 weight) public {
      address leafOperator = operator(getLeaf(position));
      uint newLeaf = makeLeaf(leafOperator, weight);
      setLeaf(position, newLeaf);
    }

    function setLeaf(uint leafPosition, uint theLeaf) public {
      uint16 leafWeight = weight(theLeaf);

      // set leaf
      leaves[leafPosition] = theLeaf;

      // set level 5
      uint childSlot = slot(leafPosition);
      uint treePosition = parent(leafPosition);
      uint treeNode = level5[treePosition];
      uint newNode = setSlot(treeNode, childSlot, leafWeight);
      level5[treePosition] = newNode;
      uint16 nodeWeight = uint16(sumWeight(newNode));

      // set level 4
      childSlot = slot(treePosition);
      treePosition = parent(treePosition);
      treeNode = level4[treePosition];
      newNode = setSlot(treeNode, childSlot, nodeWeight);
      level4[treePosition] = newNode;
      nodeWeight = uint16(sumWeight(newNode));

      // set level 3
      childSlot = slot(treePosition);
      treePosition = parent(treePosition);
      treeNode = level3[treePosition];
      newNode = setSlot(treeNode, childSlot, nodeWeight);
      level3[treePosition] = newNode;
      nodeWeight = uint16(sumWeight(newNode));

      // set level 2
      childSlot = slot(treePosition);
      treePosition = parent(treePosition);
      treeNode = level2[treePosition];
      newNode = setSlot(treeNode, childSlot, nodeWeight);
      level2[treePosition] = newNode;
      nodeWeight = uint16(sumWeight(newNode));

      // set level Root
      childSlot = slot(treePosition);
      root = setSlot(root, childSlot, nodeWeight);
    }

    function getRoot() public view returns (uint){
      return root;
    }

    function totalWeight() public view returns (uint){
      return sumWeight(root);
    }

    function pickWeightedLeaf(uint index) public view returns (uint) {
      require(index < totalWeight(), "Index greater than total weight");

      uint currentIndex = index;
      uint currentNode = root;
      uint currentPosition = 0;
      uint currentSlot;

      // get root slot
      (currentSlot, currentIndex) = pickWeightedSlot(currentNode, currentIndex);

      // get level 2 slot
      currentPosition = child(currentPosition, currentSlot);
      currentNode = level2[currentPosition];
      (currentSlot, currentIndex) = pickWeightedSlot(currentNode, currentIndex);

      // get level 3 slot
      currentPosition = child(currentPosition, currentSlot);
      currentNode = level3[currentPosition];
      (currentSlot, currentIndex) = pickWeightedSlot(currentNode, currentIndex);

      // get level 4 slot
      currentPosition = child(currentPosition, currentSlot);
      currentNode = level4[currentPosition];
      (currentSlot, currentIndex) = pickWeightedSlot(currentNode, currentIndex);

      // get level 5 slot
      currentPosition = child(currentPosition, currentSlot);
      currentNode = level5[currentPosition];
      (currentSlot, currentIndex) = pickWeightedSlot(currentNode, currentIndex);

      // get leaf
      uint leafPosition = child(currentPosition, currentSlot);

      return leafPosition;
    }

    function leafAddress(uint leaf) public view returns (address) {
      return operator(leaf);
    }

   constructor() public {
        owner = msg.sender;

        for (uint i = 0; i < 16; i++) {
          rightmostLeaf[i] = firstLeaf(i);
        }
    }

    function getOwner() public view returns (address){
        return owner;
    }

    function select(uint seed) public returns (address){
      return address(0);
    }

    function remove(uint location) public returns (bool){
        return true;

    }

}
