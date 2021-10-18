pragma solidity 0.8.6;

import "truffle/Assert.sol";
import "../contracts/DynamicArray.sol";

contract TestDynamicArray {
  using DynamicArray for DynamicArray.UintArray;

  function testUintArray() public {
    DynamicArray.UintArray memory dynamic = DynamicArray.uintArray(32);

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

  function testArrayPush() public {
    DynamicArray.UintArray memory dynamic = DynamicArray.uintArray(2);

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

    dynamic.arrayPush(123);
    Assert.equal(dynamic.array.length, 1, "Array should now have one item");
    Assert.equal(
      dynamic.array[0],
      123,
      "Array contents should be accessible normally"
    );

    dynamic.arrayPush(456);
    Assert.equal(dynamic.array.length, 2, "Array should now have two items");
    Assert.equal(
      dynamic.allocatedMemory,
      2,
      "Array should still have 2 slots of memory"
    );

    dynamic.arrayPush(789);
    Assert.equal(dynamic.array.length, 3, "Array should now have three items");
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
    DynamicArray.UintArray memory dynamic = DynamicArray.uintArray(4);
    dynamic.arrayPush(123);
    dynamic.arrayPush(456);
    dynamic.arrayPush(789);

    Assert.equal(dynamic.array.length, 3, "Array should now have three items");
    Assert.equal(dynamic.arrayPop(), 789, "Pop should return last element");
    Assert.equal(dynamic.array.length, 2, "Array should now have two items");
  }
}
