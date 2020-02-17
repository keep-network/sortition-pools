pragma solidity ^0.5.10;

library DynamicArray {
    // The in-memory dynamic Array is implemented
    // by recording the amount of allocated memory
    // separately from the length of the array.
    // This gives us a perfectly normal in-memory array
    // with all the behavior we're used to,
    // but also makes O(1) `push` operations possible
    // by expanding into the preallocated memory.
    //
    // When we run out of preallocated memory when trying to `push`,
    // we allocate twice as much and copy the array over.
    // With linear allocation costs this would amortize to O(1)
    // but with EVM allocations being actually quadratic
    // the real performance is a very technical O(N).
    // Nonetheless, this is reasonably performant in practice.
    //
    // A dynamic array can be useful
    // even when you aren't dealing with an unknown number of items.
    // Because the array tracks the allocated space
    // separately from the number of stored items,
    // you can push items into the dynamic array
    // and iterate over the currently present items
    // without tracking their number yourself,
    // or using a special null value for empty elements.
    //
    // Because Solidity doesn't really have useful safety features,
    // only enough superficial inconveniences
    // to lull yourself into a false sense of security,
    // dynamic arrays require a bit of care to handle appropriately.
    //
    // First of all,
    // dynamic arrays must not be created or modified manually.
    // Use `createArray(length)`, or `convert(existingArray)`
    // which will perform a safe and efficient conversion for you.
    // This also applies to storage;
    // in-memory dynamic arrays are for efficient in-memory operations only,
    // and it is unnecessary to store dynamic arrays.
    // Use a regular `uint256[]` instead.
    // The contents of `array` may be written like `dynamicArray.array[i] = x`
    // but never reassign the `array` pointer itself
    // nor mess with `allocatedMemory` in any way whatsoever.
    // If you fail to follow these precautions,
    // dragons inhabiting the no-man's-land
    // between the array as it's seen by Solidity
    // and the next thing allocated after it
    // will be unleashed to wreak havoc upon your memory buffers.
    //
    // Second,
    // because the `array` may be reassigned when pushing,
    // the following pattern is unsafe:
    // ```
    // Array dynamicArray;
    // uint256 len = dynamicArray.array.length;
    // uint256[] danglingPointer = dynamicArray.array;
    // danglingPointer[0] = x;
    // dynamicArray.push(y);
    // danglingPointer[0] = z;
    // ```
    // After the above code block,
    // `dynamicArray.array[0]` may be either `x` or `z`,
    // and `danglingPointer[len]` may be `y` or out of bounds.
    // This will not share your address space with a malevolent agent of chaos,
    // but it will cause entirely avoidable scratchings of the head.
    struct Array {
        // XXX: Do not modify this value.
        // In fact, do not even read it.
        // There is never a legitimate reason to do anything with this value.
        // She is quiet and wishes to be left alone.
        // The silent vigil of `allocatedMemory`
        // is the only thing standing between your contract
        // and complete chaos in its memory.
        // Respect her wish or face the monstrosities she is keeping at bay.
        uint256 allocatedMemory;
        // Unlike her sharp and vengeful sister,
        // `array` is safe to use normally
        // for anything you might do with a normal `uint256[]`.
        // Reads and loops will check bounds,
        // and writing in individual indices like `myArray.array[i] = x`
        // is perfectly fine.
        // No curse will befall you as long as you obey this rule:
        //
        // XXX: Never try to replace her or separate her from her sister
        // by writing down the accursed words
        // `myArray.array = anotherArray` or `lonelyArray = myArray.array`.
        //
        // If you do, your cattle will be diseased,
        // your children will be led astray in the woods,
        // and your memory will be silently overwritten.
        // Instead, give her a friend with
        // `mySecondArray = convert(anotherArray)`,
        // and call her by her family name first.
        // She will recognize your respect
        // and ward your memory against corruption.
        uint256[] array;
    }

    /// @notice Create an empty dynamic array,
    /// with preallocated memory for up to `length` elements.
    /// @dev Knowing or estimating the preallocated length in advance
    /// helps avoid frequent early allocations when filling the array.
    /// @param length The number of items to preallocate space for.
    /// @return A new dynamic array.
    function createArray(uint256 length) internal pure returns (Array memory) {
        uint256[] memory array = _allocate(length);
        return Array(length, array);
    }

    /// @notice Convert an existing non-dynamic array into a dynamic array.
    /// @dev The dynamic array is created
    /// with allocated memory equal to the length of the array.
    /// @param array The array to convert.
    /// @return A new dynamic array,
    /// containing the contents of the argument `array`.
    function convert(uint256[] memory array) internal pure returns (Array memory) {
        return Array(array.length, array);
    }

    /// @notice Push `item` into the dynamic array.
    /// @dev This function will be safe
    /// as long as you haven't scorned either of the sisters.
    /// If you have, the dragons will be released
    /// to wreak havoc upon your memory.
    /// A spell to dispel the curse exists,
    /// but a sacred vow prohibits it from being shared
    /// with those who do not know how to discover it on their own.
    /// @param dynamic The dynamic array to push into;
    /// after the call it will be mutated in place to contain the item,
    /// allocating more memory behind the scenes if necessary.
    /// @param item The item you wish to push into the array.
    function push(Array memory dynamic, uint256 item) internal pure {
        uint256 length = dynamic.array.length;
        uint256 allocLength = dynamic.allocatedMemory;
        // The dynamic array is full so we need to allocate more first.
        if (length >= allocLength) {
            require(length == allocLength, "Array length exceeds allocation");
            uint256 newMemory = length * 2;
            uint256[] memory newArray = _allocate(newMemory);
            _copy(newArray, dynamic.array);
            dynamic.array = newArray;
            dynamic.allocatedMemory = newMemory;
        }
        // We have enough free memory so we can push into the array.
        _push(dynamic.array, item);
    }

    /// @notice Pop the last item from the dynamic array,
    /// removing it and decrementing the array length in place.
    /// @dev This makes the dragons happy
    /// as they have more space to roam.
    /// Thus they have no desire to escape and ravage your buffers.
    /// @param dynamic The array to pop from.
    /// @return item The previously last element in the array.
    function pop(Array memory dynamic) internal pure returns (uint256 item) {
        uint256[] memory array = dynamic.array;
        uint256 length = array.length;
        require(length > 0, "Can't pop from empty array");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // Calculate the memory position of the last element
            let lastPosition := add(array, mul(length, 0x20))
            // Retrieve the last item
            item := mload(lastPosition)
            // Decrement array length
            mstore(array, sub(length, 1))
        }
        return item;
    }

    /// @notice Allocate an empty array,
    /// reserving enough memory to safely store `length` items.
    /// @dev The array starts with zero length,
    /// but the allocated buffer has space for `length` words.
    /// "What be beyond the bounds of `array`?" you may ask.
    /// The answer is: dragons.
    /// But do not worry,
    /// for `Array.allocatedMemory` protects your EVM from them.
    function _allocate(uint256 length) private pure returns (uint256[] memory) {
        uint256[] memory array;
        // Calculate the size of the allocated block.
        uint256 inMemorySize = (length + 1) * 0x20;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // Get some free memory
            array := mload(0x40)
            // Write a zero in the length field;
            // we set the length elsewhere.
            mstore(array, 0)
            // Move the free memory pointer
            // to the end of the allocated block.
            mstore(0x40, add(array, inMemorySize))
        }
        return array;
    }

    /// @notice Unsafe function to copy the contents of one array
    /// into an empty initialized array
    /// with sufficient free memory available.
    function _copy(uint256[] memory dest, uint256[] memory src) private pure {
        uint256 length = src.length;
        uint256 byteLength = length * 0x20;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // Store the resulting length of the array.
            mstore(dest, length)
            // Maintain a memory counter
            // for the current write location in the destination array
            // by adding the 32 bytes for the array length
            // to the starting location.
            let mc := add(dest, 0x20)
            // Stop copying when the memory counter reaches
            // the length of the source array.
            let end := add(mc, byteLength)

            for {
                // Initialize a copy counter to the start of the source array,
                // 32 bytes into its memory.
                let cc := add(src, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the source array into the dest memory
                // 32 bytes at a time.
                mstore(mc, mload(cc))
            }
        }
    }

    /// @notice Unsafe function to push past the limit of an array.
    /// Only use with preallocated free memory.
    function _push(uint256[] memory array, uint256 item) private pure {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // Get array length
            let length := mload(array)
            let newLength := add(length, 1)
            // Calculate how many bytes the array takes in memory,
            // including the length field
            let arraySize := mul(0x20, newLength)
            // Calculate the first memory position after the array
            let nextPosition := add(array, arraySize)
            // Store the item in the available position
            mstore(nextPosition, item)
            // Increment array length
            mstore(array, newLength)
        }
    }
}
