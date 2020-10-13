pragma solidity ^0.5.0;

import "../common/Decimal.sol";
import "../common/SafeMath.sol";
import "../model/Governable.sol";
import "../proposal/SoftwareUpgradeProposal.sol";
import "./Constants.sol";

/**
 * @dev Various constants for governance governance settings
 */
contract GovernanceSettings is Constants {
    uint256 constant _proposalFee = _proposalBurntFee + _taskHandlingReward + _taskErasingReward;
    uint256 constant _proposalBurntFee = 50 * 1e18;
    uint256 constant _taskHandlingReward = 40 * 1e18;
    uint256 constant _taskErasingReward = 10 * 1e18;
    uint256 constant _maxOptions = 10;
    uint256 constant _maxExecutionPeriod = 3 days;

    // @dev proposalFee is the fee for a proposal
    function proposalFee() public pure returns (uint256) {
        return _proposalFee;
    }

    // @dev proposalBurntFee is the burnt part of fee for a proposal
    function proposalBurntFee() public pure returns (uint256) {
        return _proposalBurntFee;
    }

    // @dev taskHandlingReward is a reward for handling each task
    function taskHandlingReward() public pure returns (uint256) {
        return _taskHandlingReward;
    }

    // @dev taskErasingReward is a reward for erasing each task
    function taskErasingReward() public pure returns (uint256) {
        return _taskErasingReward;
    }

    // @dev maxOptions maximum number of options to choose
    function maxOptions() public pure returns (uint256) {
        return _maxOptions;
    }

    // maxExecutionPeriod is maximum time for which proposal is executable after maximum voting end date
    function maxExecutionPeriod() public pure returns (uint256) {
        return _maxExecutionPeriod;
    }
}
