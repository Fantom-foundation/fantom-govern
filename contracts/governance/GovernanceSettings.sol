// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Constants} from "./Constants.sol";

/// @notice GovernanceSettings is a contract for managing governance settings
contract GovernanceSettings is Constants {
    uint256 constant public PROPOSAL_FEE = PROPOSAL_BURNT_FEE + TASK_HANDLING_REWARD + TASK_ERASING_REWARD;
    uint256 constant public PROPOSAL_BURNT_FEE = 50 * 1e18;
    uint256 constant public TASK_HANDLING_REWARD = 40 * 1e18;
    uint256 constant public TASK_ERASING_REWARD = 10 * 1e18;
    uint256 constant public MAX_OPTIONS = 10;
    uint256 constant public MAX_EXECUTION_PERIOD = 3 days;

    /// @notice proposalFee is the fee for a proposal
    /// @return proposal fee
    function proposalFee() public pure returns (uint256) {
        return PROPOSAL_FEE;
    }

    /// @notice proposalBurntFee is the burnt part of fee for a proposal
    /// @return proposal burn fee
    function proposalBurntFee() public pure returns (uint256) {
        return PROPOSAL_BURNT_FEE;
    }

    /// @notice taskHandlingReward is a reward for handling each task
    /// @return task handling reward
    function taskHandlingReward() public pure returns (uint256) {
        return TASK_HANDLING_REWARD;
    }

    /// @notice taskErasingReward is a reward for erasing each task
    /// @return task erasing reward
    function taskErasingReward() public pure returns (uint256) {
        return TASK_ERASING_REWARD;
    }

    /// @notice maxOptions maximum number of options to choose
    /// @return maximum number of options
    function maxOptions() public pure returns (uint256) {
        return MAX_OPTIONS;
    }

    /// @notice maxExecutionPeriod is maximum time for which proposal is executable after maximum voting end date
    /// @return maximum execution period
    function maxExecutionPeriod() public pure returns (uint256) {
        return MAX_EXECUTION_PERIOD;
    }
}
