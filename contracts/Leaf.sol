pragma solidity ^0.5.10;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Leaf {
    uint256 constant UINT32_MAX = 2**32 - 1;
    uint256 constant UINT64_MAX = 2**64 - 1;

    function make(address operator, uint256 creationBlock, uint256 weight)
        internal
        pure
        returns (uint256)
    {
        // Converting a bytesX type into a larger type
        // adds zero bytes on the right.
        uint256 op = uint256(bytes32(bytes20(operator)));
        // Bitwise AND the weight to erase
        // all but the 32 least significant bits
        uint256 wt = weight & UINT32_MAX;
        // Erase all but the 64 least significant bits,
        // then shift left by 32 bits to make room for the weight
        uint256 cb = (creationBlock & UINT64_MAX) << 32;
        // Bitwise OR them all together to get
        // [address operator || uint64 creationBlock || uint32 weight]
        return (uint256(bytes32(op)) | cb | wt);
    }

    function operator(uint256 leaf) internal pure returns (address) {
        // Converting a bytesX type into a smaller type
        // truncates it on the right.
        return address(bytes20(bytes32(leaf)));
    }

    /// @notice Return the block number the leaf was created in.
    function creationBlock(uint256 leaf) internal pure returns (uint256) {
        return (leaf >> 32 & UINT64_MAX);
    }

    function weight(uint256 leaf) internal pure returns (uint256) {
        // Weight is stored in the 32 least significant bits.
        // Bitwise AND ensures that we only get the contents of those bits.
        return (leaf & UINT32_MAX);
    }

    function setWeight(uint256 leaf, uint256 newWeight)
        internal pure returns (uint256)
    {
        return ((leaf & ~UINT32_MAX) | (newWeight & UINT32_MAX));
    }
}
