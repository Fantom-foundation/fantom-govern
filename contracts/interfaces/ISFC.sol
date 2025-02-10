// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/// @dev ISFC is representation of the network SFC contract for the purpose of the Governance contract. It provides weights of individual voters.
interface ISFC {
    /// @dev Get the current stake of a delegator for a specific validator.
    /// @param delegator The address of the delegator.
    /// @param toValidatorID The ID of the validator to whom the stake is delegated.
    /// @return The amount of stake delegated by given delegator to the specified validator.
    function getStake(address delegator, uint256 toValidatorID) external view returns (uint256);

    /// @dev Get information about validator for the given ID.
    /// @param validatorID The ID of the validator.
    /// @return status The information about the validator.
    function getValidator(uint256 validatorID) external view returns (
        uint256 status,
        uint256 receivedStake,
        address auth,
        uint256 createdEpoch,
        uint256 createdTime,
        uint256 deactivatedTime,
        uint256 deactivatedEpoch
    );

    /// @dev Get the current stake of a delegator for a specific validator.
    /// @param validator The address of the validator.
    /// @return The ID of the validator.
    function getValidatorID(address validator) external view returns (uint256);

    /// @dev Get the sum of all active delegated stakes.
    function getTotalActiveStake() external view returns (uint256);

    /// @notice Update slashing refund ratio for a validator.
    /// @dev The refund ratio is used to calculate the amount of stake that can be withdrawn after slashing.
    function updateSlashingRefundRatio(uint256 validatorID, uint256 refundRatio) external;

    /// @notice Check whether the given validator is slashed
    function isSlashed(uint256 validatorID) external view returns (bool);
}