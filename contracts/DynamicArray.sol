pragma solidity ^0.5.10;

contract DynamicArray {
    struct Uint256x1 {
        uint256 a;
    }

    struct Uint256x2 {
        uint256 a;
        uint256 b;
    }

    function createArray(uint256 items) public returns (uint256[] memory) {
        uint256[] memory array;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let start := mload(0x40)
            let length := 0
            for {
                let next := add(start, 0x20)
            } lt(length, items) {
                length := add(length, 1)
                next := add(next, 0x20)
            } {
                mstore(next, add(length, 0x20))
            }
            mstore(start, length)
            mstore(0x40, add(start, mul(add(length, 1), 0x20)))
            array := start
        }
        return array;
    }
}
