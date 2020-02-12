pragma solidity ^0.5.10;

library Position {
    uint256 constant UINT21_MAX = 2**21 - 1;
    uint256 constant UINT3_MAX = 2**3 - 1;
    uint256 constant LEAF_FLAG = 1 << 21;

    // Return the last 4 bits of a position number,
    // corresponding to its slot in its parent
    function slot(uint256 a) internal pure returns (uint256) {
        return a & UINT3_MAX;
    }

    // Return the parent of a position number
    function parent(uint256 a) internal pure returns (uint256) {
        return a >> 3;
    }

    // Return the location of the child of a at the given slot
    function child(uint256 a, uint256 s) internal pure returns (uint256) {
        return (a << 3) | (s & UINT3_MAX); // slot(s)
    }

    // Return the uint p as a flagged position uint:
    // the least significant 20 bits contain the position
    // and the 21th bit is set as a flag
    // to distinguish the position 0x00000 from an empty field.
    function setFlag(uint256 p) internal pure returns (uint256) {
        return (p & UINT21_MAX) | LEAF_FLAG;
    }

    // Turn a flagged position into an unflagged position
    // by removing the flag at the 21th least significant bit.
    //
    // We shouldn't _actually_ need this
    // as all position-manipulating code should ignore non-position bits anyway
    // but it's cheap to call so might as well do it.
    function unsetFlag(uint256 p) internal pure returns (uint256) {
        return p & UINT21_MAX;
    }
}
