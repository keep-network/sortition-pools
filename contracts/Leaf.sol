pragma solidity ^0.5.10;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Leaf {
    uint256 constant UINT16_MAX = 2**16 - 1;
    uint256 constant UINT80_MAX = 2**80 - 1;

    function make(address operator, uint256 creationBlock, uint256 weight)
        internal
        pure
        returns (uint256)
    {
        // Converting a bytesX type into a larger type
        // adds zero bytes on the right.
        uint256 op = uint256(bytes32(bytes20(operator)));
        // Bitwise AND the weight to erase
        // all but the 16 least significant bits
        uint256 wt = weight & UINT16_MAX;
        // Erase all but the 80 least significant bits,
        // then shift left by 16 bits to make room for the weight
        uint256 cb = (creationBlock & UINT80_MAX) << 16;
        // Bitwise OR them all together to get
        // [address operator || uint80 creationBlock || uint16 weight]
        return (uint256(bytes32(op)) | cb | wt);
    }

    function operator(uint256 leaf) internal pure returns (address) {
        // Converting a bytesX type into a smaller type
        // truncates it on the right.
        return address(bytes20(bytes32(leaf)));
    }

    /// @notice Return the block number the leaf was created in.
    function creationBlock(uint256 leaf) internal pure returns (uint256) {
        return (leaf >> 16 & UINT80_MAX);
    }

    function weight(uint256 leaf) internal pure returns (uint256) {
        // Weight is stored in the 16 least significant bits.
        // Bitwise AND ensures that we only get the contents of those bits.
        return (leaf & UINT16_MAX);
    }

    function setWeight(uint256 leaf, uint256 newWeight)
        internal pure returns (uint256)
    {
        return ((leaf & ~UINT16_MAX) | (newWeight & UINT16_MAX));
    }
}
