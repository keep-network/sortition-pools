pragma solidity ^0.5.10;

library Position {
    // Return the last 4 bits of a position number,
    // corresponding to its slot in its parent
    function slot(uint256 a) internal pure returns (uint256) {
        return a & 0xf;
    }

    // Return the parent of a position number
    function parent(uint256 a) internal pure returns (uint256) {
        return a >> 4;
    }

    // Return the location of the child of a at the given slot
    function child(uint256 a, uint256 s) internal pure returns (uint256) {
        return (a << 4) | slot(s);
    }

    // Return the trunk a leaf's position belongs to
    function trunk(uint256 a) internal pure returns (uint256) {
        return slot(a >> 16);
    }

    // Return the uint p as a flagged position uint:
    // the least significant 20 bits contain the position
    // and the 21th bit is set as a flag
    // to distinguish the position 0x00000 from an empty field.
    function setFlag(uint256 p) internal pure returns (uint256) {
        return (p & 0xfffff) | 0x100000;
    }

    // Turn a flagged position into an unflagged position
    // by removing the flag at the 21th least significant bit.
    //
    // We shouldn't _actually_ need this
    // as all position-manipulating code should ignore non-position bits anyway
    // but it's cheap to call so might as well do it.
    function unsetFlag(uint256 p) internal pure returns (uint256) {
        return p & 0xfffff;
    }
}
