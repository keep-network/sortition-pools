pragma solidity ^0.5.10;

import '../../contracts/SortitionTree.sol';

contract SortitionTreeStub is SortitionTree {
    function publicSetLeaf(uint256 position, uint256 leaf) public {
        setLeaf(position, leaf);
    }

    function publicUpdateLeaf(uint256 position, uint256 weight) public {
        updateLeaf(position, weight);
    }

    function publicRemoveLeaf(uint256 position) public {
        removeLeaf(position);
    }

    function publicInsertOperator(address op, uint256 wt) public {
        insertOperator(op, wt);
    }

    function publicRemoveOperator(address op) public {
        removeOperator(op);
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

    function publicGetFlaggedOperatorLeaf(address operator)
        public
        view
        returns (uint256)
    {
        return SortitionTree.getFlaggedOperatorLeaf(operator);
    }

    function publicPickWeightedLeaf(uint256 index) public view returns (uint256) {
        return pickWeightedLeaf(index);
    }

    function toLeaf(address op, uint256 wt) public pure returns (uint256) {
        return Leaf.make(op, wt);
    }

    function leafAddress(uint256 leaf) public pure returns (address) {
        return leaf.operator();
    }
}
