pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import './StackLib.sol';
import './Branch.sol';
import './Position.sol';
import './Trunk.sol';
import './Leaf.sol';

contract Sortition is Leaf, Position {
    using StackLib for uint256[];
    using Trunk for uint;

    // implicit tree
    uint root;
    mapping(uint => mapping(uint => uint)) branches;
    mapping(uint => uint) leaves;

    // the leaf after the rightmost occupied leaf of each stack
    uint[16] rightmostLeaf;
    // the empty leaves in each stack
    // between 0 and the rightmost occupied leaf
    uint256[][16] emptyLeaves;

    uint constant TRUNK_MAX = 2**16;

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

    function fitsUnderCap(uint addedWeight, uint trunkN) internal view returns (bool) {
      uint currentWeight = getSlot(root, trunkN);
      uint sumWeight = uint(currentWeight) + uint(addedWeight);
      return sumWeight < TRUNK_MAX;
    }

    function suitableTrunk(uint addedWeight) internal view returns (uint) {
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

    function insert(address operator, uint weight) public {
      uint theTrunk = suitableTrunk(weight);
      uint position = getEmptyLeaf(theTrunk);
      uint theLeaf = makeLeaf(operator, weight);
      setLeaf(position, theLeaf);
    }

    function toLeaf(address operator, uint weight) public pure returns (uint) {
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
        emptyLeaves[trunkN].stackPush(position);
      }
    }

    function updateLeaf(uint position, uint weight) public {
      address leafOperator = operator(getLeaf(position));
      uint newLeaf = makeLeaf(leafOperator, weight);
      setLeaf(position, newLeaf);
    }

    function setLeaf(uint position, uint theLeaf) public {
      uint childSlot;
      uint treeNode;
      uint newNode;
      uint nodeWeight = weight(theLeaf);

      // set leaf
      leaves[position] = theLeaf;

      // set levels 5 to 2
      for (uint level = 5; level >= 2; level--) {
        childSlot = slot(position);
        position = parent(position);
        treeNode = branches[level][position];
        newNode = setSlot(treeNode, childSlot, nodeWeight);
        branches[level][position] = newNode;
        nodeWeight = sumWeight(newNode);
      }

      // set level Root
      childSlot = slot(position);
      root = setSlot(root, childSlot, nodeWeight);
    }

    function getRoot() public view returns (uint){
      return root;
    }

    function totalWeight() internal view returns (uint){
      return sumWeight(root);
    }

    function pickWeightedLeaf(uint index) public returns (uint) {
      require(index < totalWeight(), "Index greater than total weight");

      uint currentIndex = index;
      uint currentNode = root;
      uint currentPosition = 0;
      uint currentSlot;

      // get root slot
      (currentSlot, currentIndex) = pickWeightedSlot(currentNode, currentIndex);

      // get slots from levels 2 to 5
      for (uint level = 2; level <= 5; level++) {
        currentPosition = child(currentPosition, currentSlot);
        currentNode = branches[level][currentPosition];
        (currentSlot, currentIndex) = pickWeightedSlot(currentNode, currentIndex);
      }

      // get leaf position
      return child(currentPosition, currentSlot);
    }

    function leafAddress(uint leaf) public view returns (address) {
      return operator(leaf);
    }

   constructor() public {
        for (uint i = 0; i < 16; i++) {
          rightmostLeaf[i] = i.firstLeaf();
        }
    }
}
