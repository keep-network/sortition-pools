pragma solidity ^0.5.10;

import "truffle/Assert.sol";
import "../contracts/DynamicArray.sol";

contract TestDynamicArray {
    using DynamicArray for DynamicArray.Array;

    function testCreateArray() public {
        DynamicArray.Array memory dynamic = DynamicArray.createArray(32);

        Assert.equal(
            dynamic.array.length,
            0,
            "Array should start with zero length"
        );
        Assert.equal(
            dynamic.allocatedMemory,
            32,
            "The array should've allocated 32 slots of memory"
        );
    }

    function testPush() public {
        DynamicArray.Array memory dynamic = DynamicArray.createArray(2);

        Assert.equal(
            dynamic.array.length,
            0,
            "Array should start with zero length"
        );
        Assert.equal(
            dynamic.allocatedMemory,
            2,
            "Array should've allocated 2 slots of memory"
        );

        dynamic.push(123);
        Assert.equal(
            dynamic.array.length,
            1,
            "Array should now have one item"
        );
        Assert.equal(
            dynamic.array[0],
            123,
            "Array contents should be accessible normally"
        );

        dynamic.push(456);
        Assert.equal(
            dynamic.array.length,
            2,
            "Array should now have two items"
        );
        Assert.equal(
            dynamic.allocatedMemory,
            2,
            "Array should still have 2 slots of memory"
        );

        dynamic.push(789);
        Assert.equal(
            dynamic.array.length,
            3,
            "Array should now have three items"
        );
        Assert.equal(
            dynamic.allocatedMemory,
            4,
            "Array should now have allocated 4 slots of memory"
        );
        Assert.equal(
            dynamic.array[0],
            123,
            "Array contents should be copied correctly"
        );
    }

    function testPop() public {
        DynamicArray.Array memory dynamic = DynamicArray.createArray(4);
        dynamic.push(123);
        dynamic.push(456);
        dynamic.push(789);

        Assert.equal(
            dynamic.array.length,
            3,
            "Array should now have three items"
        );
        Assert.equal(
            dynamic.pop(),
            789,
            "Pop should return last element"
        );
        Assert.equal(
            dynamic.array.length,
            2,
            "Array should now have two items"
        );
    }
}
