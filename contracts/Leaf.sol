pragma solidity ^0.5.10;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Leaf {
    uint256 constant UINT16_MAX = 2**16 - 1;

    function make(address operator, uint256 weight)
        internal
        pure
        returns (uint256)
    {
        bytes20 op = bytes20(operator);
        uint256 wt = weight & UINT16_MAX;
        // Converting a bytesX type into a larger type
        // adds zero bytes on the right.
        // Bitwise OR them with the 16-bit weight (prepared with bitwise AND)
        // to get [address || 10 empty bytes || weight]
        return (uint256(bytes32(op)) | wt);
    }

    function operator(uint256 leaf) internal pure returns (address) {
        // Converting a bytesX type into a smaller type
        // truncates it on the right.
        return address(bytes20(bytes32(leaf)));
    }

    function weight(uint256 leaf) internal pure returns (uint256) {
        // Weight is stored in the 16 least significant bits.
        // Bitwise AND ensures that we only get the contents of those bits.
        return (leaf & UINT16_MAX);
    }
}
