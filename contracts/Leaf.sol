pragma solidity ^0.5.10;

import "./Branch.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

library Leaf {
    using Branch for uint256;
    using BytesLib for bytes;

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
        return leaf.toBytes().toAddress(0);
    }

    function weight(uint256 leaf) internal pure returns (uint256) {
        return uint256(leaf.toBytes().toUint16(20));
    }
}
