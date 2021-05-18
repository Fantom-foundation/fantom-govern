pragma solidity ^0.5.0;

import "../model/Governable.sol";

interface SFC {
    function getStake(address _from, uint256 _toValidatorID) external view returns (uint256);

    function getValidator(uint256 _validatorID) external view returns (uint256 status, uint256 deactivatedTime, uint256 deactivatedEpoch,
        uint256 receivedStake, uint256 createdEpoch, uint256 createdTime, address auth);

    function getValidatorID(address _addr) external view returns (uint256);

    function totalActiveStake() external view returns (uint256);
}

contract SFCToGovernable is Governable {
    SFC internal sfc = SFC(address(0xFC00FACE00000000000000000000000000000000));

    // Gets the total weight of voters
    function getTotalWeight() external view returns (uint256) {
        return sfc.totalActiveStake();
    }

    // Gets the received delegated weight
    function getReceivedWeight(address addr) external view returns (uint256) {
        uint256 validatorID = sfc.getValidatorID(addr);
        if (validatorID == 0) {
            return 0;
        }
        (uint256 status, , , uint256 receivedStake, , ,) = sfc.getValidator(validatorID);
        if (status != 0) {
            return 0;
        }
        return receivedStake;
    }

    // Gets the voting weight which is delegated from the specified address to the specified address
    function getWeight(address from, address to) external view returns (uint256) {
        uint256 toValidatorID = sfc.getValidatorID(to);
        if (toValidatorID == 0) {
            return 0;
        }
        (uint256 status, , , , , ,) = sfc.getValidator(toValidatorID);
        if (status != 0) {
            return 0;
        }
        return sfc.getStake(from, toValidatorID);
    }
}
