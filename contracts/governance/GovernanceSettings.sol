// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Decimal} from "../common/Decimal.sol";
import {Governable} from "../model/Governable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice GovernanceSettings is a contract for managing governance settings
contract GovernanceSettings is Ownable {
    /// @notice proposalFee is the fee of a proposal
    uint256 public proposalFee;
    /// @notice proposalBurntFee is the burnt part of the fee for a proposal
    uint256 public proposalBurntFee;
    /// @notice taskHandlingReward is a reward for handling each task
    uint256 public taskHandlingReward;
    /// @notice taskErasingReward is a reward for erasing each task
    uint256 public taskErasingReward;
    /// @notice maxOptions is the maximum number of options that can be offered in a single proposal
    uint256 public maxOptions;
    /// @notice maxExecutionPeriod is the period after the end of voting during which the proposal can be executed
    uint256 public maxExecutionPeriod;

    // reverted when proposal fee would be under the sum of burnt fee and rewards
    error ProposalFeeTooLow(uint256 minValue);

    constructor() Ownable(msg.sender) {
        // Set default values
        proposalBurntFee = 50 * 1e18;
        taskHandlingReward = 40 * 1e18;
        taskErasingReward = 10 * 1e18;
        maxOptions = 10;
        maxExecutionPeriod = 72 hours;
        proposalFee = proposalBurntFee + taskHandlingReward + taskErasingReward;
    }

    /// @notice setProposalFee sets the fee for a proposal
    /// @param _proposalFee new proposal fee in wei of native tokens
    function setProposalFee(uint256 _proposalFee) public onlyOwner {
        uint256 minProposalFee = proposalBurntFee + taskHandlingReward + taskErasingReward;
        if(_proposalFee < minProposalFee) {
            revert ProposalFeeTooLow(minProposalFee);
        }
        proposalFee = _proposalFee;
    }

    /// @notice setProposalBurntFee sets the burnt part of fee for a proposal
    /// @param _proposalBurntFee new proposal burn fee in wei of native tokens
    function setProposalBurntFee(uint256 _proposalBurntFee) public onlyOwner {
        uint256 minProposalFee = _proposalBurntFee + taskHandlingReward + taskErasingReward;
        // Proposal fee must always be greater than or equal to sum of burntFee and rewards
        if (minProposalFee > proposalFee) {
            revert ProposalFeeTooLow(minProposalFee);
        }
        proposalBurntFee = _proposalBurntFee;
    }

    /// @notice setTaskHandlingReward sets a reward for handling each task
    /// @param _taskHandlingReward new task handling reward in wei of native tokens
    function setTaskHandlingReward(uint256 _taskHandlingReward) public onlyOwner {
        uint256 minProposalFee = proposalBurntFee + _taskHandlingReward + taskErasingReward;
        // Proposal fee must always be greater than or equal to sum of burntFee and rewards
        if (minProposalFee > proposalFee) {
            revert ProposalFeeTooLow(minProposalFee);
        }
        taskHandlingReward = _taskHandlingReward;
    }

    /// @notice setTaskErasingReward sets a reward for erasing each task
    /// @param _taskErasingReward new task erasing reward in wei of native tokens
    function setTaskErasingReward(uint256 _taskErasingReward) public onlyOwner {
        uint256 minProposalFee = proposalBurntFee + taskHandlingReward + _taskErasingReward;
        // Proposal fee must always be greater than or equal to sum of burntFee and rewards
        if (minProposalFee > proposalFee) {
            revert ProposalFeeTooLow(minProposalFee);
        }
        taskErasingReward = _taskErasingReward;
    }

    /// @notice setMaxOptions sets maximum number of options to choose
    /// @param _maxOptions new maximum number of options
    function setMaxOptions(uint256 _maxOptions) public onlyOwner {
        maxOptions = _maxOptions;
    }

    /// @notice setMaxExecutionPeriod sets the period after the end of voting during which the proposal can be executed
    /// @param _maxExecutionPeriod new maximum execution period in seconds
    function setMaxExecutionPeriod(uint256 _maxExecutionPeriod) public onlyOwner {
        maxExecutionPeriod = _maxExecutionPeriod;
    }

    /// @notice calculates the minimum number of votes required for a proposal
    /// @param totalWeight The total weight of the voters
    /// @param minVotesRatio The minimum ratio of votes required
    /// @return The minimum number of votes required
    function minVotesAbsolute(uint256 totalWeight, uint256 minVotesRatio) public pure returns (uint256) {
        return totalWeight * minVotesRatio / Decimal.unit();
    }
}
