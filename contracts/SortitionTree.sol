pragma solidity 0.8.6;

import "./Branch.sol";
import "./Position.sol";
import "./Leaf.sol";

contract SortitionTree {
  using Branch for uint256;
  using Position for uint256;
  using Leaf for uint256;

  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 private constant SLOT_BITS = 3;
  uint256 private constant LEVELS = 7;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 private constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 private constant SLOT_WIDTH = 256 / SLOT_COUNT;
  uint256 private constant SLOT_MAX = (2**SLOT_WIDTH) - 1;
  uint256 private constant POOL_CAPACITY = SLOT_COUNT**LEVELS;
  ////////////////////////////////////////////////////////////////////////////

  // implicit tree
  // root 8
  // level2 64
  // level3 512
  // level4 4k
  // level5 32k
  // level6 256k
  // level7 2M
  uint256 internal root;
  mapping(uint256 => mapping(uint256 => uint256)) internal branches;
  mapping(uint256 => uint256) internal leaves;

  // the flagged (see setFlag() and unsetFlag() in Position.sol) positions
  // of all operators present in the pool
  mapping(address => uint256) internal flaggedLeafPosition;

  // the leaf after the rightmost occupied leaf of each stack
  uint256 internal rightmostLeaf;
  // the empty leaves in each stack
  // between 0 and the rightmost occupied leaf
  uint256[] internal emptyLeaves;

  // Each operator has an uint32 ID number
  // which is allocated when they first join the pool
  // and remains unchanged even if they leave and rejoin the pool.
  mapping(address => uint256) internal operatorID;
  // The idAddress array records the address corresponding to each ID number.
  // The ID number 0 is initialized with a zero address and is not used.
  address[] internal idAddress;

  constructor() {
    root = 0;
    rightmostLeaf = 0;
    idAddress.push();
  }

  // Return the ID number of the given operator address.
  // An ID number of 0 means the operator has not been allocated an ID number yet.
  function getOperatorID(address operator) public view returns (uint256) {
    return operatorID[operator];
  }

  // Get the operator address corresponding to the given ID number.
  // An empty address means the ID number has not been allocated yet.
  function getIDOperator(uint256 id) public view returns (address) {
    return idAddress.length > id ? idAddress[id] : address(0);
  }

  // checks if operator is already registered in the pool
  function isOperatorRegistered(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  // Sum the number of operators in each trunk
  function operatorsInPool() public view returns (uint256) {
    // Get the number of leaves that might be occupied;
    // if `rightmostLeaf` equals `firstLeaf()` the tree must be empty,
    // otherwise the difference between these numbers
    // gives the number of leaves that may be occupied.
    uint256 nPossiblyUsedLeaves = rightmostLeaf;
    // Get the number of empty leaves
    // not accounted for by the `rightmostLeaf`
    uint256 nEmptyLeaves = emptyLeaves.length;

    return (nPossiblyUsedLeaves - nEmptyLeaves);
  }

  function totalWeight() public view returns (uint256) {
    return root.sumWeight();
  }

  // Give the operator a new ID number
  // Does not check if the operator already has an ID number
  function allocateOperatorID(address operator) internal returns (uint256) {
    uint256 id = idAddress.length;
    operatorID[operator] = id;
    idAddress.push(operator);
    return id;
  }

  function _insertOperator(address operator, uint256 weight) internal {
    require(
      !isOperatorRegistered(operator),
      "Operator is already registered in the pool"
    );

    uint256 id = getOperatorID(operator);
    if (id == 0) {
      id = allocateOperatorID(operator);
    }

    uint256 position = getEmptyLeafPosition();
    // Record the block the operator was inserted in
    uint256 theLeaf = Leaf.make(operator, block.number, id);

    root = setLeaf(position, theLeaf, weight, root);

    // Without position flags,
    // the position 0x000000 would be treated as empty
    flaggedLeafPosition[operator] = position.setFlag();
  }

  function _removeOperator(address operator) internal {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    require(flaggedPosition != 0, "Operator is not registered in the pool");
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();
    root = removeLeaf(unflaggedPosition, root);
    removeLeafPositionRecord(operator);
  }

  function updateOperator(address operator, uint256 weight) internal {
    require(
      isOperatorRegistered(operator),
      "Operator is not registered in the pool"
    );

    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();
    root = updateLeaf(unflaggedPosition, weight, root);
  }

  function removeLeafPositionRecord(address operator) internal {
    flaggedLeafPosition[operator] = 0;
  }

  function removeLeaf(uint256 position, uint256 _root)
    internal
    returns (uint256)
  {
    uint256 rightmostSubOne = rightmostLeaf - 1;
    bool isRightmost = position == rightmostSubOne;

    uint256 newRoot = setLeaf(position, 0, 0, _root);

    if (isRightmost) {
      rightmostLeaf = rightmostSubOne;
    } else {
      emptyLeaves.push(position);
    }
    return newRoot;
  }

  function updateLeaf(
    uint256 position,
    uint256 weight,
    uint256 _root
  ) internal returns (uint256) {
    if (getLeafWeight(position) != weight) {
      return updateTree(position, weight, _root);
    } else {
      return _root;
    }
  }

  function setLeaf(
    uint256 position,
    uint256 theLeaf,
    uint256 leafWeight,
    uint256 _root
  ) internal returns (uint256) {
    // set leaf
    leaves[position] = theLeaf;

    return (updateTree(position, leafWeight, _root));
  }

  function updateTree(
    uint256 position,
    uint256 weight,
    uint256 _root
  ) internal returns (uint256) {
    uint256 childSlot;
    uint256 treeNode;
    uint256 newNode;
    uint256 nodeWeight = weight;

    uint256 parent = position;
    // set levels 7 to 2
    for (uint256 level = LEVELS; level >= 2; level--) {
      childSlot = parent.slot();
      parent = parent.parent();
      treeNode = branches[level][parent];
      newNode = treeNode.setSlot(childSlot, nodeWeight);
      branches[level][parent] = newNode;
      nodeWeight = newNode.sumWeight();
    }

    // set level Root
    childSlot = parent.slot();
    return _root.setSlot(childSlot, nodeWeight);
  }

  function getEmptyLeafPosition() internal returns (uint256) {
    uint256 rLeaf = rightmostLeaf;
    bool spaceOnRight = (rLeaf + 1) < POOL_CAPACITY;
    if (spaceOnRight) {
      rightmostLeaf = rLeaf + 1;
      return rLeaf;
    } else {
      uint256 emptyLeafCount = emptyLeaves.length;
      require(emptyLeafCount > 0, "Pool is full");
      uint256 emptyLeaf = emptyLeaves[emptyLeafCount - 1];
      emptyLeaves.pop();
      return emptyLeaf;
    }
  }

  function getFlaggedLeafPosition(address operator)
    internal
    view
    returns (uint256)
  {
    return flaggedLeafPosition[operator];
  }

  function getLeafWeight(uint256 position) internal view returns (uint256) {
    uint256 slot = position.slot();
    uint256 parent = position.parent();
    uint256 node = branches[LEVELS][parent];
    return node.getSlot(slot);
  }

  function pickWeightedLeaf(uint256 index, uint256 _root)
    internal
    view
    returns (uint256 leafPosition)
  {
    uint256 currentIndex = index;
    uint256 currentNode = _root;
    uint256 currentPosition = 0;
    uint256 currentSlot;

    require(index < currentNode.sumWeight(), "Index exceeds weight");

    // get root slot
    (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);

    // get slots from levels 2 to 7
    for (uint256 level = 2; level <= LEVELS; level++) {
      currentPosition = currentPosition.child(currentSlot);
      currentNode = branches[level][currentPosition];
      (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);
    }

    // get leaf position
    leafPosition = currentPosition.child(currentSlot);
  }
}
