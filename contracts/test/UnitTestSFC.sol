pragma solidity ^0.5.0;

import "../adapters/SFCToGovernable.sol";

/// @dev UnitTestSFC is a dummy SFC used for testing
contract UnitTestSFC is SFC {
    struct Validator {
        uint256 status;
        uint256 receivedStake;
        bool isSlashed;
        uint256 slashingRefundRatio;
    }

    mapping(address => uint256) public validatorIDs;
    mapping(uint256 => Validator) public validators;
    mapping(address => mapping(uint256 => uint256)) public stakes;
    uint256 public totalActiveStake;


    function getStake(address delegator, uint256 toValidatorID) external view returns (uint256) {
        return stakes[delegator][toValidatorID];
    }

    function getValidator(uint256 validatorID) external view returns (
        uint256 status,
        uint256 receivedStake,
        address auth,
        uint256 createdEpoch,
        uint256 createdTime,
        uint256 deactivatedTime,
        uint256 deactivatedEpoch
    ) {
        Validator storage v = validators[validatorID];
        // we only care about status and received stake
        return (v.status, v.receivedStake, address(0), 0, 0, 0, 0);
    }

    function getValidatorID(address validator) external view returns (uint256) {
        return validatorIDs[validator];
    }

    function getTotalActiveStake() external view returns (uint256) {
        return totalActiveStake;
    }

    function updateSlashingRefundRatio(uint256 validatorID, uint256 refundRatio) external {
        validators[validatorID].slashingRefundRatio = refundRatio;
    }

    function isSlashed(uint256 validatorID) public view returns (bool) {
        return validators[validatorID].isSlashed;
    }

    function addValidator(uint256 id, uint256 status, address addr) external {
        validators[id] = Validator(status, 0, false);
        validatorIDs[addr] = id;
    }

    function stake(address to, uint256 amount) external {
        uint256 id = validatorIDs[to];
        validators[id].receivedStake += amount;
        stakes[msg.sender][id] += amount;
        totalActiveStake += amount;
    }

    function unstake(address from, uint256 amount) external {
        uint256 id = validatorIDs[from];
        require(stakes[msg.sender][id] >= amount, "not enough stake");
        validators[id].receivedStake -= amount;
        stakes[msg.sender][id] -= amount;
        totalActiveStake -= amount;
    }

    function slash(uint256 validatorId) external {
        validators[validatorId].isSlashed = true;
    }
}