pragma solidity 0.8.17;

import "@thesis/solidity-contracts/contracts/token/ERC20WithPermit.sol";
import "@thesis/solidity-contracts/contracts/token/IReceiveApproval.sol";

contract TokenStub is ERC20WithPermit {
    constructor () ERC20WithPermit("Test", "TEST") {}
}
