pragma solidity ^0.5.10;

import '../../contracts/SortitionTree.sol';

contract SortitionTreeStub is SortitionTree {
    function setLeaf(uint256 position, uint256 leaf) public {
        SortitionTree.setLeaf(position, leaf);
    }

    function removeLeaf(uint256 position) public {
        SortitionTree.removeLeaf(position);
    }

    function getLeaf(uint256 position) public view returns (uint256) {
        return leaves[position];
    }

    function getRoot() public view returns (uint256) {
        return root;
    }

    function getFlaggedOperatorLeaf(address operator)
        public
        view
        returns (uint256)
    {
        return SortitionTree.getFlaggedOperatorLeaf(operator);
    }

    function toLeaf(address op, uint256 wt) public pure returns (uint256) {
        return Leaf.make(op, wt);
    }

    function leafAddress(uint256 leaf) public pure returns (address) {
        return leaf.operator();
    }
}
