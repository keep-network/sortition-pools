pragma solidity 0.8.17;

import "../../contracts/SortitionTree.sol";

contract SortitionTreeStub is SortitionTree {
    using Leaf for uint256;

    function publicSetLeaf(uint256 position, uint256 leaf, uint256 weight) public {
        root = setLeaf(position, leaf, weight, root);
        if (rightmostLeaf <= position) {
            rightmostLeaf = position + 1;
        }
    }

    function publicUpdateLeaf(uint256 position, uint256 weight) public {
        root = updateLeaf(position, weight, root);
    }

    function publicRemoveLeaf(uint256 position) public {
        root = removeLeaf(position, root);
    }

    function publicInsertOperator(address op, uint256 wt) public {
        _insertOperator(op, wt);
    }

    function publicRemoveOperator(address op) public {
        _removeOperator(op);
    }

    function publicIsOperatorRegistered(address op) public view returns (bool) {
        return isOperatorRegistered(op);
    }

    function getLeaf(uint256 position) public view returns (uint256) {
        return leaves[position];
    }

    function getRoot() public view returns (uint256) {
        return root;
    }

    function publicGetFlaggedLeafPosition(address operator)
        public
        view
        returns (uint256)
    {
        return SortitionTree.getFlaggedLeafPosition(operator);
    }

    function publicPickWeightedLeaf(uint256 index) public view returns (uint256) {
        uint256 leafPosition = pickWeightedLeaf(
            index,
            root
        );
        return leafPosition;
    }

    function toLeaf(address op, uint256 wt) public view returns (uint256) {
        return Leaf.make(op, block.number, wt);
    }

    function leafAddress(uint256 leaf) public pure returns (address) {
        return leaf.operator();
    }
}
