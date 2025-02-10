// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Decimal} from "../common/Decimal.sol";
import {Governable} from "../model/Governable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice GovernanceSettings is a contract for managing governance settings
contract GovernanceSettings is Ownable {
    uint256 private _proposalFee;
    uint256 private _proposalBurntFee;
    uint256 private _taskHandlingReward;
    uint256 private _taskErasingReward;
    uint256 private _maxOptions;
    uint256 private _maxExecutionPeriod;

    // reverted when proposal fee would be under the sum of burnt fee and rewards
    error ProposalFeeTooLow(uint256 necessaryValue);

    constructor() Ownable(msg.sender) {
        // Set default values
        _proposalBurntFee = 50 * 1e18;
        _taskHandlingReward = 40 * 1e18;
        _taskErasingReward = 10 * 1e18;
        _maxOptions = 10;
        _maxExecutionPeriod = 72 hours;
        _proposalFee = _proposalBurntFee + _taskHandlingReward + _taskErasingReward;
    }

    /// @notice proposalFee is the fee for a proposal
    /// @return proposal fee
    function proposalFee() public view returns (uint256) {
        return _proposalFee;
    }

    /// @notice proposalBurntFee is the burnt part of fee for a proposal
    /// @return proposal burn fee
    function proposalBurntFee() public view returns (uint256) {
        return _proposalBurntFee;
    }

    /// @notice taskHandlingReward is a reward for handling each task
    /// @return task handling reward
    function taskHandlingReward() public view returns (uint256) {
        return _taskHandlingReward;
    }

    /// @notice taskErasingReward is a reward for erasing each task
    /// @return task erasing reward
    function taskErasingReward() public view returns (uint256) {
        return _taskErasingReward;
    }

    /// @notice maxOptions maximum number of options to choose
    /// @return maximum number of options
    function maxOptions() public view returns (uint256) {
        return _maxOptions;
    }

    /// @notice maxExecutionPeriod is maximum time for which proposal is executable after maximum voting end date
    /// @return maximum execution period in hours
    function maxExecutionPeriod() public view returns (uint256) {
        return _maxExecutionPeriod;
    }


    /// @notice setProposalFee sets the fee for a proposal
    /// @param __proposalFee new proposal fee in native tokens
    function setProposalFee(uint256 __proposalFee) public onlyOwner {
        __proposalFee = __proposalFee * 1e18;
        uint256 necessarySum = _proposalBurntFee + _taskHandlingReward + _taskErasingReward;
        if(__proposalFee < necessarySum) {
            revert ProposalFeeTooLow(necessarySum);
        }
        _proposalFee = __proposalFee;
    }

    /// @notice setProposalBurntFee sets the burnt part of fee for a proposal and
    /// @param __proposalBurntFee new proposal burn fee in native tokens
    function setProposalBurntFee(uint256 __proposalBurntFee) public onlyOwner {
        __proposalBurntFee = __proposalBurntFee * 1e18;
        uint256 newProposalFee = __proposalBurntFee + _taskHandlingReward + _taskErasingReward;
        // Proposal fee must always be greater than or equal to sum of burntFee and rewards
        if (newProposalFee > _proposalFee) {
            revert ProposalFeeTooLow(newProposalFee);
        }
        _proposalBurntFee = __proposalBurntFee;
    }

    /// @notice setTaskHandlingReward sets a reward for handling each task and
    /// @notice and if necessary updates proposalFee accordingly
    /// @param __taskHandlingReward new task handling reward in native tokens
    function setTaskHandlingReward(uint256 __taskHandlingReward) public onlyOwner {
        __taskHandlingReward = __taskHandlingReward * 1e18;
        uint256 newProposalFee = _proposalBurntFee + __taskHandlingReward + _taskErasingReward;
        // Proposal fee must always be greater than or equal to sum of burntFee and rewards
        if (newProposalFee > _proposalFee) {
            revert ProposalFeeTooLow(newProposalFee);
        }
        _taskHandlingReward = __taskHandlingReward;
    }

    /// @notice setTaskErasingReward sets a reward for erasing each task and
    /// @notice and if necessary updates proposalFee accordingly
    /// @param __taskErasingReward new task erasing reward in native tokens
    function setTaskErasingReward(uint256 __taskErasingReward) public onlyOwner {
        __taskErasingReward = __taskErasingReward * 1e18;
        uint256 newProposalFee = _proposalBurntFee + _taskHandlingReward + __taskErasingReward;
        // Proposal fee must always be greater than or equal to sum of burntFee and rewards
        if (newProposalFee > _proposalFee) {
            revert ProposalFeeTooLow(newProposalFee);
        }
        _taskErasingReward = __taskErasingReward;
    }

    /// @notice setMaxOptions sets maximum number of options to choose
    /// @param __maxOptions new maximum number of options
    function setMaxOptions(uint256 __maxOptions) public onlyOwner {
        _maxOptions = __maxOptions;
    }

    /// @notice setMaxExecutionPeriod sets maximum time for which proposal is executable after maximum voting end date
    /// @param __maxExecutionPeriod new maximum execution period in hours
    function setMaxExecutionPeriod(uint256 __maxExecutionPeriod) public onlyOwner {
        _maxExecutionPeriod = __maxExecutionPeriod * 1 hours;
    }

    /// @notice calculates the minimum number of votes required for a proposal
    /// @param totalWeight The total weight of the voters
    /// @param minVotesRatio The minimum ratio of votes required
    /// @return The minimum number of votes required
    function minVotesAbsolute(uint256 totalWeight, uint256 minVotesRatio) public pure returns (uint256) {
        return totalWeight * minVotesRatio / Decimal.unit();
    }
}
