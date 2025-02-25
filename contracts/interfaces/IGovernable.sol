// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;


/// @notice IGovernable.sol defines the main interface for all governable items
interface IGovernable {
    /// @notice Retrieves the total active stake across all validators.
    /// @return The sum of all active delegated stakes.
    function getTotalWeight() external view returns (uint256);

    /// @notice Retrieves the total delegated stake received by a specific validator.
    /// @param validator The address of the validator whose received stake is being queried.
    /// @return The total amount of stake delegated to the specified validator.
    function getReceivedWeight(address validator) external view returns (uint256);

    /// @notice Retrieves the voting weight of a given delegator for a specified validator.
    /// @param delegator The address of the delegator whose voting weight is being queried.
    /// @param validator The address of the validator to whom the stake is delegated.
    /// @return The voting weight (stake) of the delegator for the specified validator.
    function getWeight(address delegator, address validator) external view returns (uint256);
}
