pragma solidity ^0.5.10;

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

    function insertOperator(address operator, uint weight) public {
      require(
        getFlaggedOperatorLeaf(operator) == 0,
        "Operator is already registered in the pool"
      );

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

    function removeOperator(address operator) public {
      uint flaggedLeaf = getFlaggedOperatorLeaf(operator);

      require(flaggedLeaf != 0, "Operator is not registered in the pool");

      uint unflaggedLeaf = flaggedLeaf.unsetFlag();
      releaseGas(operator);
      removeLeaf(unflaggedLeaf);
      removeOperatorLeaf(operator);
    }

    function operatorsInTrunk(uint trunkN) public view returns (uint) {
      // Get the number of leaves that might be occupied;
      // if `rightmostLeaf` equals `firstLeaf()` the trunk must be empty,
      // otherwise the difference between these numbers
      // gives the number of leaves that may be occupied.
      uint nPossiblyUsedLeaves = rightmostLeaf[trunkN] - trunkN.firstLeaf();
      // Get the number of empty leaves
      // not accounted for by the `rightmostLeaf`
      uint nEmptyLeaves = emptyLeaves[trunkN].getSize();

      return (nPossiblyUsedLeaves - nEmptyLeaves);
    }

    // Sum the number of operators in each trunk
    function operatorsInPool() public view returns (uint) {
      uint sum;
      for (uint i = 0; i < 16; i++) {
        sum += operatorsInTrunk(i);
      }
      return sum;
    }

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

    function pickWeightedLeafWithIndex(uint index) public view returns (uint, uint) {

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
      uint leafPosition = currentPosition.child(currentSlot);
      // get the first index of the leaf
      // This works because the last weight returned from `pickWeightedSlot()`
      // equals the "overflow" from getting the current slot.
      uint leafFirstIndex = index - currentIndex;
      return (leafPosition, leafFirstIndex);
    }

    function pickWeightedLeaf(uint index) public view returns (uint) {
      uint leafPosition;
      uint _ignoredIndex;
      (leafPosition, _ignoredIndex) = pickWeightedLeafWithIndex(index);
      return leafPosition;
    }

    function leafAddress(uint leaf) public pure returns (address) {
      return leaf.operator();
    }

   constructor() public {
        for (uint i = 0; i < 16; i++) {
          rightmostLeaf[i] = i.firstLeaf();
        }
    }
}
