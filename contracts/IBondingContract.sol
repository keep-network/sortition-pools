pragma solidity ^0.5.10;

/// @title A third party Bonding Contract providing information to the pool
/// about operator's eligibility for work selection.
interface IBondingContract {
    /// @notice Function checks if the provided operator is eligible for work
    /// selection given the bonding requirements.
    ///
    /// The function returns true if the actual staker weight of the operator is
    /// equal or greater than the weight in the argument, and the operator is
    /// eligible for work selection from that pool, and any bond required can
    /// be created.
    ///
    /// The function returning false due to the operator not being eligble for
    /// work selection, the provided weight exceeds its actual staker weight, or
    /// any required bond is not possible to be created.
    ///
    /// Operators for which this function returns false are removed from the
    /// pool and not taken into account for work selection.
    function isEligible(
        address operator,
        uint256 stakingWeight,
        uint256 bondSize
    ) external returns (bool);
}
