pragma solidity ^0.5.10;

library Trunk {
    // The number of operators a single trunk can hold.
    uint256 constant TRUNK_SIZE = 2**16;

    // the first leaf of the trunk
    function firstLeaf(uint256 trunkN) internal pure returns (uint256) {
        return TRUNK_SIZE * trunkN;
    }

    // the last leaf of the trunk
    function lastLeaf(uint256 trunkN) internal pure returns (uint256) {
        return TRUNK_SIZE * (trunkN + 1) - 1;
    }
}
