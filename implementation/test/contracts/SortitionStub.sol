pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import '../../contracts/Sortition.sol';
contract SortitionStub is Sortition {
    uint256[] stack;

    function stackPush(uint256 _element) public {
        stack.stackPush(_element);
    }

    function stackPop() public {
        stack.stackPop();
    }

    function stackPeek() public {
        stack.stackPeek();
    }

      function getSize() public {
        stack.getSize();
    }
}
