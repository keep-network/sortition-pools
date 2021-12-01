pragma solidity 0.8.9;

interface IPoolStaking {
    function rolesOf(
        address operator
    ) external view returns (address owner, address beneficiary, address authorizer);
}
