pragma solidity ^0.5.10;

interface ISortitionPool {
    /// @notice Selects a new group of operators of the provided size based on
    /// the provided pseudo-random seed. At least one operator has to be
    /// registered in the pool, otherwise the function fails reverting the
    /// transaction.
    /// @param groupSize Size of the requested group
    /// @param seed Pseudo-random number used to select operators to group
    /// @return selected Members of the selected group
    function selectGroup(uint256 groupSize, bytes32 seed)
        external returns (address[] memory selected);

    /// @notice Selects a new group of operators of the provided size based on
    /// the provided pseudo-random seed. All operators in the group are unique.
    ///
    /// If there are not enough operators in a pool to form a group or not
    /// enough operators are eligible for work selection, the function fails.
    /// @param groupSize Size of the requested group
    /// @param seed Pseudo-random number used to select operators to group
    /// @return selected Members of the selected group
    function selectSetGroup(uint256 groupSize, bytes32 seed)
        external returns (address[] memory selected);

    // Return whether the operator is eligible for the pool.
    function isOperatorEligible(address operator) external view returns (bool);

    // Return whether the operator is present in the pool.
    function isOperatorInPool(address operator) external view returns (bool);

    // Return whether the operator is up to date in the pool.
    // If the operator is eligible but not present, return False.
    function isOperatorUpToDate(address operator) external view returns (bool);

    // Add an operator to the pool,
    // reverting if the operator is already present.
    function joinPool(address operator) external;

    // Update the operator's weight if present and eligible,
    // or remove from the pool if present and ineligible.
    function updateOperatorStatus(address operator) external;
}
