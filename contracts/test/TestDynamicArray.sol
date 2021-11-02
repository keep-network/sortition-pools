pragma solidity 0.8.6;

import "../DynamicArray.sol";

contract TestDynamicArray {
  using DynamicArray for DynamicArray.UintArray;

  function runUintArrayTest() public {
    DynamicArray.UintArray memory dynamic = DynamicArray.uintArray(32);
    require(dynamic.array.length == 0, "Array should start with zero length");
    require(dynamic.allocatedMemory == 32, "The array should've allocated 32 slots of memory");
  }

  function runArrayPushTest() public {
    DynamicArray.UintArray memory dynamic = DynamicArray.uintArray(2);
    require(dynamic.array.length == 0, "Array should start with zero length");
    require(dynamic.allocatedMemory == 2,"Array should've allocated 2 slots of memory" );

    dynamic.arrayPush(123);
    require(dynamic.array.length == 1, "Array should now have one item");
    require(dynamic.array[0] == 123, "Array contents should be accessible");

    dynamic.arrayPush(456);
    require(dynamic.array.length == 2, "Array should now have two items");
    require(dynamic.allocatedMemory == 2, "Array should still have 2 slots of memory");

    dynamic.arrayPush(789);
    require(dynamic.array.length == 3, "Array should now have three items");
    require(dynamic.allocatedMemory == 4, "Array should now have allocated 4 slots of memory");
    require(dynamic.array[0] == 123, "Array contents should be copied correctly");
  }

  function runArrayPopTest() public {
    DynamicArray.UintArray memory dynamic = DynamicArray.uintArray(4);
    dynamic.arrayPush(123);
    dynamic.arrayPush(456);
    dynamic.arrayPush(789);

    require(dynamic.array.length == 3, "Array should now have three items");
    require(dynamic.arrayPop() == 789, "Pop should return last element");
    require(dynamic.array.length == 2, "Array should now have two items");
  }
}
