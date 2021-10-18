pragma solidity 0.8.6;

library Leaf {
    ////////////////////////////////////////////////////////////////////////////
    // Parameters for configuration

    // How many bits a position uses per level of the tree;
    // each branch of the tree contains 2**SLOT_BITS slots.
    uint256 private constant SLOT_BITS = 3;
    ////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////
    // Derived constants, do not touch
    uint256 private constant SLOT_COUNT = 2**SLOT_BITS;
    uint256 private constant SLOT_WIDTH = 256 / SLOT_COUNT;
    uint256 private constant SLOT_MAX = (2**SLOT_WIDTH) - 1;

    uint256 private constant ID_WIDTH = SLOT_WIDTH;
    uint256 private constant ID_MAX = SLOT_MAX;

    uint256 private constant BLOCKHEIGHT_WIDTH = 96 - ID_WIDTH;
    uint256 private constant BLOCKHEIGHT_MAX = (2**BLOCKHEIGHT_WIDTH) - 1;

    ////////////////////////////////////////////////////////////////////////////

    function make(
        address _operator,
        uint256 _creationBlock,
        uint256 _id
    ) internal pure returns (uint256) {
        // Converting a bytesX type into a larger type
        // adds zero bytes on the right.
        uint256 op = uint256(bytes32(bytes20(_operator)));
        // Bitwise AND the id to erase
        // all but the 32 least significant bits
        uint256 uid = _id & ID_MAX;
        // Erase all but the 64 least significant bits,
        // then shift left by 32 bits to make room for the id
        uint256 cb = (_creationBlock & BLOCKHEIGHT_MAX) << ID_WIDTH;
        // Bitwise OR them all together to get
        // [address operator || uint64 creationBlock || uint32 id]
        return (op | cb | uid);
    }

    function operator(uint256 leaf) internal pure returns (address) {
        // Converting a bytesX type into a smaller type
        // truncates it on the right.
        return address(bytes20(bytes32(leaf)));
    }

    /// @notice Return the block number the leaf was created in.
    function creationBlock(uint256 leaf) internal pure returns (uint256) {
        return ((leaf >> ID_WIDTH) & BLOCKHEIGHT_MAX);
    }

    function id(uint256 leaf) internal pure returns (uint256) {
        // Id is stored in the 32 least significant bits.
        // Bitwise AND ensures that we only get the contents of those bits.
        return (leaf & ID_MAX);
    }
}
