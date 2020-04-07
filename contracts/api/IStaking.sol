pragma solidity ^0.5.10;

interface IStaking {
    // Gives the amount of KEEP tokens staked by the `operator`
    // eligible for work selection in the specified `operatorContract`.
    //
    // If the operator doesn't exist or hasn't finished initializing,
    // or the operator contract hasn't been authorized for the operator,
    // returns 0.
    function eligibleStake(
        address operator,
        address operatorContract
    ) external view returns (uint256);

    // Gives the current minimum amount of KEEP that has to be staked by
    // operator so that it can join the pool.
    function minimumStake() external view returns (uint256);
}
