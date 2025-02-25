// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IGovernable} from "../interfaces/IGovernable.sol";
import {ISFC} from "../interfaces/ISFC.sol";

// @dev SFCToGovernable is an adapter allowing to use the network SFC contract as IGovernable.sol (governance votes weights provider).
contract SFCGovernableAdapter is IGovernable {
    ISFC internal immutable sfc;

    constructor(address _sfcAddress) {
        sfc = ISFC(_sfcAddress);
    }

    /// @dev Retrieves the total active stake across all validators.
    /// @return The sum of all active delegated stakes.
    function getTotalWeight() external view returns (uint256) {
        return sfc.getTotalActiveStake();
    }

    /// @dev Retrieves the total delegated stake received by a specific validator.
    /// @param validator The address of the validator whose received stake is being queried.
    /// @return The total amount of stake delegated to the specified validator.
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

    /// @dev Retrieves the voting weight of a given delegator for a specified validator.
    /// @param delegator The address of the delegator whose voting weight is being queried.
    /// @param validator The address of the validator to whom the stake is delegated.
    /// @return The voting weight (stake) of the delegator for the specified validator.
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
