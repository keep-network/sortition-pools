pragma solidity ^0.5.10;

library Position {
    // Parameters for configuration

    // How many bits a position uses per level of the tree;
    // each branch of the tree contains 2**SLOT_BITS slots.
    uint256 constant SLOT_BITS = 4;
    // How many levels the tree uses, including root.
    uint256 constant LEVELS = 5;

    // Derived constants, do not touch
    uint256 constant SLOT_MAX = (2 ** SLOT_BITS) - 1;
    uint256 constant POSITION_BITS = LEVELS * SLOT_BITS;
    uint256 constant POSITION_MAX = (2 ** POSITION_BITS) - 1;
    uint256 constant LEAF_FLAG = 1 << POSITION_BITS;

    // Return the last 4 bits of a position number,
    // corresponding to its slot in its parent
    function slot(uint256 a) internal pure returns (uint256) {
        return a & SLOT_MAX;
    }

    // Return the parent of a position number
    function parent(uint256 a) internal pure returns (uint256) {
        return a >> SLOT_BITS;
    }

    // Return the location of the child of a at the given slot
    function child(uint256 a, uint256 s) internal pure returns (uint256) {
        return (a << SLOT_BITS) | (s & SLOT_MAX); // slot(s)
    }

    // Return the trunk a leaf's position belongs to
    function trunk(uint256 a) internal pure returns (uint256) {
        return (a >> (POSITION_BITS - SLOT_BITS)) & SLOT_MAX; // slot(a >> 16)
    }

    // Return the uint p as a flagged position uint:
    // the least significant 20 bits contain the position
    // and the 21th bit is set as a flag
    // to distinguish the position 0x00000 from an empty field.
    function setFlag(uint256 p) internal pure returns (uint256) {
        return (p & POSITION_MAX) | LEAF_FLAG;
    }

    // Turn a flagged position into an unflagged position
    // by removing the flag at the 21th least significant bit.
    //
    // We shouldn't _actually_ need this
    // as all position-manipulating code should ignore non-position bits anyway
    // but it's cheap to call so might as well do it.
    function unsetFlag(uint256 p) internal pure returns (uint256) {
        return p & POSITION_MAX;
    }
}
