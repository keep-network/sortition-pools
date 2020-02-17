pragma solidity ^0.5.10;

library DynamicArray {
    struct Array {
        uint256 allocatedMemory;
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

    /// @notice Push `item` into the dynamic array,
    /// allocating more memory behind the scenes if necessary.
    function push(Array memory dynamic, uint256 item) internal pure {
        uint256 length = dynamic.array.length;
        uint256 allocLength = dynamic.allocatedMemory;
        require(
            length <= allocLength,
            "The dynamic array is broken"
        );
        // The dynamic array is full so we need to allocate more first.
        if (length == allocLength) {
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
    /// removing it and shortening the array length.
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
            // Calculate how many bytes the array takes in memory,
            // including the length field
            let arraySize := mul(0x20, add(length, 1))
            // Calculate the first memory position after the array
            let nextPosition := add(array, arraySize)
            // Store the item in the available position
            mstore(nextPosition, item)
            // Increment array length
            mstore(array, add(length, 1))
        }
    }
}
