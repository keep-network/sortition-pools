pragma solidity ^0.5.10;

import "./StackLib.sol";
import "./Branch.sol";
import "./Position.sol";
import "./Trunk.sol";
import "./Leaf.sol";

contract SortitionTree {
    using StackLib for uint256[];
    using Branch for uint256;
    using Position for uint256;
    using Leaf for uint256;

    // implicit tree
    // root 8
    // level2 64
    // level3 512
    // level4 4k
    // level5 32k
    // level6 256k
    // level7 2M
    uint256 root;
    mapping(uint256 => mapping(uint256 => uint256)) branches;
    mapping(uint256 => uint256) leaves;

    // the flagged (see setFlag() and unsetFlag() in Position.sol) positions
    // of all operators present in the pool
    mapping(address => uint256) operatorLeaves;

    // the leaf after the rightmost occupied leaf of each stack
    uint256 rightmostLeaf;
    // the empty leaves in each stack
    // between 0 and the rightmost occupied leaf
    uint256[] emptyLeaves;

    constructor() public {
        root = 0;
        rightmostLeaf = 0;
    }

    // checks if operator is already registered in the pool
    function isOperatorRegistered(address operator) public view returns (bool) {
        return getFlaggedOperatorLeaf(operator) != 0;
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
        uint256 nEmptyLeaves = emptyLeaves.getSize();

        return (nPossiblyUsedLeaves - nEmptyLeaves);
    }

    function insertOperator(address operator, uint256 weight) internal {
        require(
            !isOperatorRegistered(operator),
            "Operator is already registered in the pool"
        );

        uint256 position = getSuitableEmptyLeaf(weight);
        uint256 theLeaf = Leaf.make(operator, block.number, weight);

        setLeaf(position, theLeaf);

        // Without position flags,
        // the position 0x00000 would be treated as empty
        operatorLeaves[operator] = position.setFlag();
    }

    function removeOperator(address operator) internal {
        uint256 flaggedLeaf = getFlaggedOperatorLeaf(operator);
        require(
            flaggedLeaf != 0,
            "Operator is not registered in the pool"
        );
        uint256 unflaggedLeaf = flaggedLeaf.unsetFlag();
        removeLeaf(unflaggedLeaf);
        removeOperatorLeaf(operator);
    }

    function updateOperator(address operator, uint256 weight) internal {
        require(
            isOperatorRegistered(operator),
            "Operator is not registered in the pool"
        );

        uint256 flaggedLeaf = getFlaggedOperatorLeaf(operator);
        uint256 unflaggedLeaf = flaggedLeaf.unsetFlag();
        updateLeaf(unflaggedLeaf, weight);
    }

    function removeOperatorLeaf(address operator) internal {
        operatorLeaves[operator] = 0;
    }

    function getFlaggedOperatorLeaf(address operator)
        internal
        view
        returns (uint256)
    {
        return operatorLeaves[operator];
    }

    function removeLeaf(uint256 position) internal {
        uint256 rightmostSubOne = rightmostLeaf - 1;
        bool isRightmost = position == rightmostSubOne;

        setLeaf(position, 0);

        if (isRightmost) {
            rightmostLeaf = rightmostSubOne;
        } else {
            emptyLeaves.stackPush(position);
        }
    }

    function updateLeaf(uint256 position, uint256 weight) internal {
        uint256 oldLeaf = leaves[position];
        if (oldLeaf.weight() != weight) {
            uint256 newLeaf = oldLeaf.setWeight(weight);
            setLeaf(position, newLeaf);
        }
    }

    function setLeaf(uint256 position, uint256 theLeaf) internal {
        uint256 childSlot;
        uint256 treeNode;
        uint256 newNode;
        uint256 nodeWeight = theLeaf.weight();

        // set leaf
        leaves[position] = theLeaf;

        uint256 parent = position;
        // set levels 5 to 2
        for (uint256 level = 7; level >= 2; level--) {
            childSlot = parent.slot();
            parent = parent.parent();
            treeNode = branches[level][parent];
            newNode = treeNode.setSlot(childSlot, nodeWeight);
            branches[level][parent] = newNode;
            nodeWeight = newNode.sumWeight();
        }

        // set level Root
        childSlot = parent.slot();
        root = root.setSlot(childSlot, nodeWeight);
    }

    function pickWeightedLeafWithIndex(uint256 index)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 currentIndex = index;
        uint256 currentNode = root;
        uint256 currentPosition = 0;
        uint256 currentSlot;

        require(index < currentNode.sumWeight(), "Index exceeds weight");

        // get root slot
        (currentSlot, currentIndex) = currentNode.pickWeightedSlot(
            currentIndex
        );

        // get slots from levels 2 to 5
        for (uint256 level = 2; level <= 7; level++) {
            currentPosition = currentPosition.child(currentSlot);
            currentNode = branches[level][currentPosition];
            (currentSlot, currentIndex) = currentNode.pickWeightedSlot(
                currentIndex
            );
        }

        // get leaf position
        uint256 leafPosition = currentPosition.child(currentSlot);
        // get the first index of the leaf
        // This works because the last weight returned from `pickWeightedSlot()`
        // equals the "overflow" from getting the current slot.
        uint256 leafFirstIndex = index - currentIndex;
        return (leafPosition, leafFirstIndex);
    }

    function pickWeightedLeaf(uint256 index) internal view returns (uint256) {
        uint256 leafPosition;
        uint256 _ignoredIndex;
        (leafPosition, _ignoredIndex) = pickWeightedLeafWithIndex(index);
        return leafPosition;
    }

    function getSuitableEmptyLeaf(uint256 addedWeight)
        internal returns (uint256)
    {
        bool emptyLeavesInStack = leavesInStack();
        if (emptyLeavesInStack) {
            return emptyLeaves.stackPop();
        } else {
            uint256 rLeaf = rightmostLeaf;
            rightmostLeaf = rLeaf + 1;
            return rLeaf;
        }
    }

    function leavesInStack() internal view returns (bool) {
        return emptyLeaves.getSize() > 0;
    }

    function totalWeight() internal view returns (uint256) {
        return root.sumWeight();
    }
}
