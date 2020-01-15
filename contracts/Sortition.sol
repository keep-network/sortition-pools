pragma solidity ^0.5.10;

import './StackLib.sol';
import './Branch.sol';
import './Position.sol';
import './Trunk.sol';
import './Leaf.sol';
import "./GasStation.sol";

library Sortition {
    using StackLib for uint256[];
    using Branch for uint;
    using Position for uint;
    using Trunk for uint;
    using Leaf for uint;

    struct SortitionPool {
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
    }

    uint constant TRUNK_MAX = 2**16;

    function leavesInStack(SortitionPool storage pool, uint trunkN)
      internal
      view
      returns (bool)
    {
      return pool.emptyLeaves[trunkN].getSize() > 0;
    }

    function leavesToRight(SortitionPool storage pool, uint trunkN)
      internal
      view
      returns (bool)
    {
      return pool.rightmostLeaf[trunkN] <= trunkN.lastLeaf();
    }

    function hasSpace(SortitionPool storage pool, uint trunkN)
      internal
      view
      returns (bool)
    {
      return leavesInStack(pool, trunkN) || leavesToRight(pool, trunkN);
    }

    function getEmptyLeaf(SortitionPool storage pool, uint trunkN)
      internal
      returns (uint)
    {
      require(hasSpace(pool, trunkN), "Trunk is full");
      if (leavesInStack(pool, trunkN)) {
        return pool.emptyLeaves[trunkN].stackPop();
      } else {
        uint newLeafPosition = pool.rightmostLeaf[trunkN];
        pool.rightmostLeaf[trunkN] = newLeafPosition + 1;
        return newLeafPosition;
      }
    }

    function fitsUnderCap(
        SortitionPool storage pool,
        uint addedWeight,
        uint trunkN
    ) internal view returns (bool) {
      uint currentWeight = pool.root.getSlot(trunkN);
      uint sumWeight = uint(currentWeight) + uint(addedWeight);
      return sumWeight < TRUNK_MAX;
    }

    function suitableTrunk(
      SortitionPool storage pool,
      uint addedWeight
    ) internal view returns (uint) {
      uint theTrunk;

      for (theTrunk = 0; theTrunk < 16; theTrunk++) {
        bool weightOkay = fitsUnderCap(pool, addedWeight, theTrunk);
        bool spaceOkay = hasSpace(pool, theTrunk);
        if (weightOkay && spaceOkay) {
          break;
        }
      }
      return theTrunk;
    }

    function insert(
      SortitionPool storage pool,
      address operator,
      uint weight
    ) public {
      uint theTrunk = suitableTrunk(pool, weight);
      uint position = getEmptyLeaf(pool, theTrunk);
      uint theLeaf = Leaf.make(operator, weight);

      setLeaf(pool, position, theLeaf);

      // Without position flags,
      // the position 0x00000 would be treated as empty
      pool.operatorLeaves[operator] = position.setFlag();

    }

    /* function removeOperator(address operator) public returns (uint) { */
    function removeOperator(
      SortitionPool storage pool,
      address operator
    ) public {
      uint flaggedLeaf = getFlaggedOperatorLeaf(pool, operator);

      if (flaggedLeaf != 0) {
        uint unflaggedLeaf = flaggedLeaf.unsetFlag();
        removeLeaf(pool, unflaggedLeaf);
        removeOperatorLeaf(pool, operator);
      }

      /* uint a = pickWeightedLeaf(1); */
      /* uint b = pickWeightedLeaf(2); */
      /* uint c = pickWeightedLeaf(3); */

      /* return a + b + c; */
    }

    function removeOperatorLeaf(SortitionPool storage pool, address operator)
      public
    {
      pool.operatorLeaves[operator] = 0;
    }

    function getFlaggedOperatorLeaf(SortitionPool storage pool, address operator)
      public
      view
      returns (uint)
    {
      return pool.operatorLeaves[operator];
    }

    function toLeaf(address operator, uint weight) public pure returns (uint) {
      return Leaf.make(operator, weight);
    }

    function getLeaf(SortitionPool storage pool, uint position)
      public
      view
      returns (uint)
    {
      return pool.leaves[position];
    }

    function removeLeaf(SortitionPool storage pool, uint position) public {
      uint trunkN = position.trunk();
      uint rightmostSubOne = pool.rightmostLeaf[trunkN] - 1;
      bool isRightmost = position == rightmostSubOne;

      setLeaf(pool, position, 0);

      if (isRightmost) {
        pool.rightmostLeaf[trunkN] = rightmostSubOne;
      } else {
        pool.emptyLeaves[trunkN].stackPush(position);
      }
    }

    function updateLeaf(SortitionPool storage pool, uint position, uint weight) public {
      address leafOperator = getLeaf(pool, position).operator();
      uint newLeaf = Leaf.make(leafOperator, weight);
      setLeaf(pool, position, newLeaf);
    }

    function setLeaf(SortitionPool storage pool, uint position, uint theLeaf) public {
      uint childSlot;
      uint treeNode;
      uint newNode;
      uint nodeWeight = theLeaf.weight();

      // set leaf
      pool.leaves[position] = theLeaf;

      // set levels 5 to 2
      for (uint level = 5; level >= 2; level--) {
        childSlot = position.slot();
        position = position.parent();
        treeNode = pool.branches[level][position];
        newNode = treeNode.setSlot(childSlot, nodeWeight);
        pool.branches[level][position] = newNode;
        nodeWeight = newNode.sumWeight();
      }

      // set level Root
      childSlot = position.slot();
      treeNode = pool.root;
      newNode = treeNode.setSlot(childSlot, nodeWeight);
      pool.root = newNode;
    }

    function getRoot(SortitionPool storage pool) public view returns (uint){
      return pool.root;
    }

    function totalWeight(SortitionPool storage pool) internal view returns (uint){
      return pool.root.sumWeight();
    }

    function pickWeightedLeaf(SortitionPool storage pool, uint index)
      public
      view
      returns (uint)
    {

      uint currentIndex = index;
      uint currentNode = pool.root;
      uint currentPosition = 0;
      uint currentSlot;

      require(index < currentNode.sumWeight(), "Index exceeds weight");

      // get root slot
      (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);

      // get slots from levels 2 to 5
      for (uint level = 2; level <= 5; level++) {
        currentPosition = currentPosition.child(currentSlot);
        currentNode = pool.branches[level][currentPosition];
        (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);
      }

      // get leaf position
      return currentPosition.child(currentSlot);
    }

    function leafAddress(uint leaf) public pure returns (address) {
      return leaf.operator();
    }

    /* function initializePool(SortitionPool storage pool) public { */
    /*   uint[16] memory r; */
    /*   for (uint i = 0; i < 16; i++) { */
    /*     r[i] = i.firstLeaf(); */
    /*   } */

    /*   uint256[][16] memory t; */
    /*   return (r, t); */
      
    /* } */
    function initializeTrunks(SortitionPool storage pool) public {
      for (uint i = 0; i < 16; i++) {
        pool.rightmostLeaf[i] = i.firstLeaf();
      }
    }
}
