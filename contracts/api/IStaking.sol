pragma solidity 0.8.9;

interface IStaking {
    function rolesOf(
        address operator
    ) external view returns (address owner, address beneficiary, address authorizer);
}
