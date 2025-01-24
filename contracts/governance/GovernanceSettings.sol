// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../common/Decimal.sol";
import "../model/Governable.sol";
import "../proposal/SoftwareUpgradeProposal.sol";
import "./Constants.sol";

/// @dev Various constants for governance governance settings
contract GovernanceSettings is Constants {
    uint256 constant _proposalFee = _proposalBurntFee + _taskHandlingReward + _taskErasingReward;
    uint256 constant _proposalBurntFee = 50 * 1e18;
    uint256 constant _taskHandlingReward = 40 * 1e18;
    uint256 constant _taskErasingReward = 10 * 1e18;
    uint256 constant _maxOptions = 10;
    uint256 constant _maxExecutionPeriod = 3 days;

    /// @dev proposalFee is the fee for a proposal
    /// @return proposal fee
    function proposalFee() public pure returns (uint256) {
        return _proposalFee;
    }

    /// @dev proposalBurntFee is the burnt part of fee for a proposal
    /// @return proposal burn fee
    function proposalBurntFee() public pure returns (uint256) {
        return _proposalBurntFee;
    }

    /// @dev taskHandlingReward is a reward for handling each task
    /// @return task handling reward
    function taskHandlingReward() public pure returns (uint256) {
        return _taskHandlingReward;
    }

    /// @dev taskErasingReward is a reward for erasing each task
    /// @return task erasing reward
    function taskErasingReward() public pure returns (uint256) {
        return _taskErasingReward;
    }

    /// @dev maxOptions maximum number of options to choose
    /// @return maximum number of options
    function maxOptions() public pure returns (uint256) {
        return _maxOptions;
    }

    /// @dev maxExecutionPeriod is maximum time for which proposal is executable after maximum voting end date
    /// @return maximum execution period
    function maxExecutionPeriod() public pure returns (uint256) {
        return _maxExecutionPeriod;
    }
}
