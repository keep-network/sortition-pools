// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '../../contracts/SortitionTree.sol';
contract StackStub is SortitionTree {
    using StackLib for uint256[];

    uint256[] stack;

    function stackPush(uint256 _element) public {
        stack.stackPush(_element);
    }

    function stackPop() public returns (uint256) {
        return stack.stackPop();
    }

    function stackPeek() public view returns (uint256) {
        return stack.stackPeek();
    }

    function getSize() public view returns (uint256) {
        return stack.getSize();
    }
}
