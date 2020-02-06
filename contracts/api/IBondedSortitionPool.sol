pragma solidity ^0.5.10;

interface IBondedSortitionPool {
    /// @notice Selects a new group of operators of the provided size based on
    /// the provided pseudo-random seed and bonding requirements. All operators
    /// in the group are unique.
    ///
    /// If there are not enough operators in a pool to form a group or not
    /// enough operators are eligible for work selection given the bonding
    /// requirements, the function fails.
    /// @param groupSize Size of the requested group
    /// @param seed Pseudo-random number used to select operators to group
    /// @param bondSize Size of the requested bond per operator
    /// @return selected Members of the selected group
    function selectSetGroup(uint256 groupSize, bytes32 seed, uint256 bondValue)
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
