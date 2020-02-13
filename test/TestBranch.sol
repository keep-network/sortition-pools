pragma solidity ^0.5.10;

import "truffle/Assert.sol";
import "../contracts/Branch.sol";

contract TestBranch {
    using Branch for *;

    uint256 node = 0x7777777766666666555555554444444433333333222222221111111100000000;

    function testGetSlot() public {
        uint256 slot = node.getSlot(3);
        Assert.equal(slot, 0x33333333, "getSlot() should return the slot");
    }

    function testClearSlot() public {
        uint256 newNode = node.clearSlot(3);
        uint256 expected = 0x7777777766666666555555554444444400000000222222221111111100000000;
        Assert.equal(newNode, expected, "clearSlot() should clear the slot");
    }

    function testSetSlot() public {
        uint256 newNode = node.setSlot(3, 0x01234567);
        uint256 expected = 0x7777777766666666555555554444444401234567222222221111111100000000;
        Assert.equal(newNode, expected, "setSlot() should set the slot");
    }

    function testSumWeight() public {
        uint256 weight = node.sumWeight();
        uint256 expected = 0x77777777 * 4;
        Assert.equal(weight, expected, "sumWeight() should return the total weight");
    }

    function testPickWeightedSlot() public {
        uint256[3] memory weights = [uint256(0), 1, 0x11111222];
        uint256[3] memory indices = [uint256(1), 1, 2];
        uint256[3] memory surpluses = [uint256(0), 1, 0x111];
        uint index;
        uint surplus;
        for (uint i = 0; i < 3; i++) {
            (index, surplus) = node.pickWeightedSlot(weights[i]);
            Assert.equal(
                index,
                indices[i],
                "pickWeightedSlot() index incorrect"
            );
            Assert.equal(
                surplus,
                surpluses[i],
                "pickWeightedSlot() surplus incorrect"
            );
        }
    }
}
