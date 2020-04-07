pragma solidity 0.5.17;

import '../../contracts/RNG.sol';

contract RNGStub {
    function bitsRequired(uint range) public pure returns (uint) {
        return RNG.bitsRequired(range);
    }

    function truncate(uint bits, uint input) public pure returns (uint) {
        return RNG.truncate(bits, input);
    }

    function getIndex(uint range, uint state) public view returns (uint) {
        uint i;
        bytes32 s;
        (i, s) = RNG.getIndex(range, bytes32(state));
        return i;
    }
}
