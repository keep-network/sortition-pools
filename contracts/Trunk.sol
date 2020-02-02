pragma solidity ^0.5.10;

library Trunk {
    uint256 constant trunkSize = 65536;

    // the first leaf of the trunk
    function firstLeaf(uint256 trunkN) internal pure returns (uint256) {
        return trunkSize * trunkN;
    }

    // the last leaf of the trunk
    function lastLeaf(uint256 trunkN) internal pure returns (uint256) {
        return trunkSize * (trunkN + 1) - 1;
    }
}
