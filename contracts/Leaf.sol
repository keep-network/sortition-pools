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
        return (uint256(bytes32(op)) | wt);
    }

    function operator(uint256 leaf) internal pure returns (address) {
        return address(bytes20(bytes32(leaf)));
    }

    function weight(uint256 leaf) internal pure returns (uint256) {
        return (leaf & UINT16_MAX);
    }
}
