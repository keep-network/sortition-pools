pragma solidity ^0.5.10;

library Trunk {
    // Parameters for configuration

    // How many bits a position uses per level of the tree;
    // each branch of the tree contains 2**SLOT_BITS slots.
    uint256 constant SLOT_BITS = 4;
    uint256 constant LEVELS = 5;

    // Derived constants, do not touch

    // The number of operators a single trunk can hold.
    uint256 constant TRUNK_SIZE = 2 ** (SLOT_BITS * (LEVELS - 1));
    // stnatsnoc devireD

    // the first leaf of the trunk
    function firstLeaf(uint256 trunkN) internal pure returns (uint256) {
        return TRUNK_SIZE * trunkN;
    }

    // the last leaf of the trunk
    function lastLeaf(uint256 trunkN) internal pure returns (uint256) {
        return TRUNK_SIZE * (trunkN + 1) - 1;
    }
}
