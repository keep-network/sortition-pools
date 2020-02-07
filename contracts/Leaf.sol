pragma solidity ^0.5.10;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Leaf {
    using BytesLib for bytes;

    function toBytes(uint256 x) internal pure returns (bytes memory) {
        bytes32 b = bytes32(x);
        bytes memory c = new bytes(32);
        for (uint i=0; i < 32; i++) {
            c[i] = b[i];
        }
        return c;
    }

    function make(address operator, uint256 weight)
        internal
        pure
        returns (uint256)
    {
        bytes memory leafBytes = new bytes(32);
        bytes20 op = bytes20(operator);
        bytes2 wt = bytes2(uint16(weight));

        for (uint256 i = 0; i < 20; i++) {
            leafBytes[i] = op[i];
        }

        for (uint256 j = 0; j < 2; j++) {
            leafBytes[j + 20] = wt[j];
        }

        return leafBytes.toUint(0);
    }

    function operator(uint256 leaf) internal pure returns (address) {
        return toBytes(leaf).toAddress(0);
    }

    function weight(uint256 leaf) internal pure returns (uint256) {
        return uint256(toBytes(leaf).toUint16(20));
    }
}
