pragma solidity ^0.5.10;

import "truffle/Assert.sol";
import "../contracts/DynamicArray.sol";

contract TestDynamicArray is DynamicArray {
    function testCreateArray() public {
        uint256[] memory array = createArray(32);

        Assert.equal(array.length, 32, "Dynamic array should be allocated correctly");
        Assert.equal(array[10], 42, "Items in the array should be correct");
        Assert.equal(array[31], 63, "Items in the array should be correct");
    }
}
