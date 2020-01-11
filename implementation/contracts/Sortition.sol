pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import './StackLib.sol';
import './Branch.sol';
import './Position.sol';
import './Trunk.sol';
import './Leaf.sol';
import "./GasStation.sol";

contract Sortition is GasStation {
    using StackLib for uint256[];
    using Branch for uint;
    using Position for uint;
    using Trunk for uint;
    using Leaf for uint;

    // implicit tree
    uint root;
    mapping(uint => mapping(uint => uint)) branches;
    mapping(uint => uint) leaves;

    // the flagged (see setFlag() and unsetFlag() in Position.sol) positions
    // of all operators present in the pool
    mapping(address => uint) operatorLeaves;

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
      uint currentWeight = root.getSlot(trunkN);
      uint sumWeight = uint(currentWeight) + uint(addedWeight);
      return sumWeight < TRUNK_MAX;
    }

    function suitableTrunk(uint addedWeight) internal view returns (uint) {
      uint theTrunk;

      for (theTrunk = 0; theTrunk < 16; theTrunk++) {
        bool weightOkay = fitsUnderCap(addedWeight, theTrunk);
        bool spaceOkay = hasSpace(theTrunk);
        if (weightOkay && spaceOkay) {
          break;
        }
      }
      return theTrunk;
    }

    function insert(address operator, uint weight) public {
      uint theTrunk = suitableTrunk(weight);
      uint position = getEmptyLeaf(theTrunk);
      uint theLeaf = Leaf.make(operator, weight);

      // Set superfluous storage so we can later unset them for a refund
      depositGas(operator);

      setLeaf(position, theLeaf);

      // Without position flags,
      // the position 0x00000 would be treated as empty
      operatorLeaves[operator] = position.setFlag();

    }

    function removeOperator(address operator) public returns (uint) {
      uint flaggedLeaf = getFlaggedOperatorLeaf(operator);

      if (flaggedLeaf != 0) {
        uint unflaggedLeaf = flaggedLeaf.unsetFlag();
        releaseGas(operator);
        removeLeaf(unflaggedLeaf);
        removeOperatorLeaf(operator);
      }

      uint a = pickWeightedLeaf(1);
      uint b = pickWeightedLeaf(2);
      uint c = pickWeightedLeaf(3);

      return a + b + c;
    }

    function removeOperatorLeaf(address operator) public {
      operatorLeaves[operator] = 0;
    }

    function getFlaggedOperatorLeaf(address operator) public view returns (uint) {
      return operatorLeaves[operator];
    }

    function toLeaf(address operator, uint weight) public pure returns (uint) {
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

    function updateLeaf(uint position, uint weight) public {
      address leafOperator = getLeaf(position).operator();
      uint newLeaf = Leaf.make(leafOperator, weight);
      setLeaf(position, newLeaf);
    }

    function setLeaf(uint position, uint theLeaf) public {
      uint childSlot;
      uint treeNode;
      uint newNode;
      uint nodeWeight = theLeaf.weight();

      // set leaf
      leaves[position] = theLeaf;

      // set levels 5 to 2
      for (uint level = 5; level >= 2; level--) {
        childSlot = position.slot();
        position = position.parent();
        treeNode = branches[level][position];
        newNode = treeNode.setSlot(childSlot, nodeWeight);
        branches[level][position] = newNode;
        nodeWeight = newNode.sumWeight();
      }

      // set level Root
      childSlot = position.slot();
      root = root.setSlot(childSlot, nodeWeight);
    }

    function getRoot() public view returns (uint){
      return root;
    }

    function totalWeight() internal view returns (uint){
      return root.sumWeight();
    }

    function pickWeightedLeaf(uint index) public returns (uint) {

      uint currentIndex = index;
      uint currentNode = root;
      uint currentPosition = 0;
      uint currentSlot;

      require(index < currentNode.sumWeight(), "Index exceeds weight");

      // get root slot
      (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);

      // get slots from levels 2 to 5
      for (uint level = 2; level <= 5; level++) {
        currentPosition = currentPosition.child(currentSlot);
        currentNode = branches[level][currentPosition];
        (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);
      }

      // get leaf position
      return currentPosition.child(currentSlot);
    }

    function pickThreeLeaves(uint ia, uint ib, uint ic) public returns (uint) {
      uint a = pickWeightedLeaf(ia);
      uint b = pickWeightedLeaf(ib);
      uint c = pickWeightedLeaf(ic);

      return (a + b + c);
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
