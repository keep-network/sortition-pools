pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import '../../contracts/Sortition.sol';
contract StackStub is Sortition {
    uint256[] stack;

    function stackPush(uint256 _element) public {
        stack.stackPush(_element);
    }

    function stackPop() public returns (uint256) {
        return stack.stackPop();
    }

    function stackPeek() public  returns (uint256) {
        return stack.stackPeek();
    }

    function getSize() public returns (uint256) {
        return stack.getSize();
    }
}
