pragma solidity 0.8.6;

interface IStaking {
    function rolesOf(
        address operator
    ) external view returns (address, address, address);
}
