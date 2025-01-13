pragma solidity ^0.5.0;

import "../model/Governable.sol";

// todo maybe move to governable
interface SFC {
    function getStake(address delegator, uint256 toValidatorID) external view returns (uint256);

    function getValidator(uint256 validatorID) external view returns (
        uint256 status,
        uint256 receivedStake,
        address auth,
        uint256 createdEpoch,
        uint256 createdTime,
        uint256 deactivatedTime,
        uint256 deactivatedEpoch
    );

    function getValidatorID(address validator) external view returns (uint256);

    function getTotalActiveStake() external view returns (uint256);
}

contract SFCToGovernable is Governable {
    SFC internal sfc = SFC(address(0xFC00FACE00000000000000000000000000000000));

    /**
     * @notice Retrieves the total active stake across all validators.
     * @dev This function returns the total amount of stake that is currently active in the system.
     * @return The sum of all active delegated stakes.
     */
    function getTotalWeight() external view returns (uint256) {
        return sfc.getTotalActiveStake();
    }

    /**
     * @notice Retrieves the total delegated stake received by a specific validator.
     * @dev Returns 0 if the validator is not found or SFC does not return STATUS_OK.
     * @param validator The address of the validator whose received stake is being queried.
     * @return The total amount of stake delegated to the specified validator.
     */
    function getReceivedWeight(address validator) external view returns (uint256) {
        uint256 validatorID = sfc.getValidatorID(validator);
        if (validatorID == 0) {
            return 0;
        }
        (uint256 status, uint256 receivedStake, , , , ,) = sfc.getValidator(validatorID);
        if (status != 0) {
            return 0;
        }
        return receivedStake;
    }

    /**
     * @notice Retrieves the voting weight of a given delegator for a specified validator.
     * @dev Returns 0 if the validator is not found or is not active.
     * @param delegator The address of the delegator whose voting weight is being queried.
     * @param validator The address of the validator to whom the stake is delegated.
     * @return The voting weight (stake) of the delegator for the specified validator.
     */
    function getWeight(address delegator, address validator) external view returns (uint256) {
        uint256 toValidatorID = sfc.getValidatorID(validator);
        if (toValidatorID == 0) {
            return 0;
        }
        (uint256 status, , , , , ,) = sfc.getValidator(toValidatorID);
        if (status != 0) {
            return 0;
        }
        return sfc.getStake(delegator, toValidatorID);
    }
}
