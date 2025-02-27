// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Governable} from "../model/Governable.sol";
import {IProposal} from "../interfaces/IProposal.sol";
import {IProposalVerifier} from "../verifiers/IProposalVerifier.sol";
import {Proposal} from "./Proposal.sol";
import {GovernanceSettings} from "./GovernanceSettings.sol";
import {LRC} from "./LRC.sol";
import {Version} from "../version/Version.sol";
import {VotesBookKeeper} from "../votesbook/VotesBookKeeper.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @notice Governance contract for voting on proposals
contract Governance is Initializable, ReentrancyGuardTransient, GovernanceSettings, Version {
    using LRC for LRC.Option;

    struct Vote {
        uint256 weight; // Weight of the vote
        uint256[] choices; // Votes choices
    }

    // ProposalState.status constants
    enum ProposalStatus {
        INITIAL,
        RESOLVED,
        FAILED,
        CANCELED,
        EXECUTION_EXPIRED
    }

    struct ProposalState {
        Proposal.Parameters params;

        mapping(uint256 => LRC.Option) options; // Voting state OptionID => LRC.Option
        uint256 winnerOptionID;
        uint256 votes; // Sum of total weight of votes
        ProposalStatus status;
    }

    uint256 constant public TASK_VOTING = 1;
    struct Task {
        bool active;
        uint256 assignment;
        uint256 proposalID;
    }

    Governable public governableContract; // SFC to Governable adapter refer to SFCToGovernable.sol
    IProposalVerifier public proposalVerifier;
    uint256 public lastProposalID;

    Task[] public tasks; // Tasks of all current proposals

    // ProposalID => ProposalState
    mapping(uint256 => ProposalState) internal _proposals;
    // voter address => proposalID => weight
    mapping(address => mapping(uint256 => uint256)) public overriddenWeight;
    // voter => delegationReceiver => proposalID => Vote
    mapping(address => mapping(address => mapping(uint256 => Vote))) internal _votes;

    VotesBookKeeper public votebook;

    /// @notice Emitted when a new proposal is created.
    /// @param proposalID ID of newly created proposal.
    event ProposalCreated(uint256 proposalID);

    /// @notice Emitted when a proposal is resolved.
    /// @param proposalID ID of newly created proposal.
    event ProposalResolved(uint256 proposalID);

    /// @notice Emitted when a proposal is rejected.
    /// @param proposalID ID of newly created proposal.
    event ProposalRejected(uint256 proposalID);

    /// @notice Emitted when a proposal is canceled.
    /// @param proposalID ID of newly created proposal.
    event ProposalCanceled(uint256 proposalID);

    /// @notice Emitted when a proposal has expired.
    /// @param proposalID ID of newly created proposal.
    event ProposalExecutionExpired(uint256 proposalID);

    /// @notice Emitted when a task (or tasks) is handled.
    /// @param startIdx Index of the first task handled.
    /// @param endIdx Index of the last task handled.
    /// @param handled Number of tasks handled.
    event TasksHandled(uint256 startIdx, uint256 endIdx, uint256 handled);

    /// @notice Emitted when a task (or tasks) is erased.
    /// @param quantity Number of tasks erased.
    event TasksErased(uint256 quantity);

    /// @notice Emitted when a weight of a voted has been override.
    /// @param voter Address of the voter.
    /// @param diff Weight difference.
    event VoteWeightOverridden(address voter, uint256 diff);

    /// @notice Emitted when a weight of a voted has been un-override.
    /// @param voter Address of the voter.
    /// @param diff Weight difference.
    event VoteWeightUnOverridden(address voter, uint256 diff);

    /// @notice Emitted when a vote is cast.
    /// @param voter Address of the voter.
    /// @param delegatedTo The address which the voter has delegated their stake to.
    /// @param proposalID ID of the proposal.
    /// @param choices Choices of the vote.
    /// @param weight Weight of the vote.
    event Voted(address voter, address delegatedTo, uint256 proposalID, uint256[] choices, uint256 weight);

    /// @notice Emitted when a vote is canceled.
    /// @param voter Address of the voter.
    /// @param delegatedTo The address which the voter has delegated their stake to.
    /// @param proposalID ID of the proposal.
    event VoteCanceled(address voter, address delegatedTo, uint256 proposalID);

    /// @notice Initialize the contract.
    /// @param _governableContract The address of the governable contract.
    /// @param _proposalVerifier The address of the proposal verifier.
    /// @param _votebook The address of the votebook contract.
    function initialize(address _governableContract, address _proposalVerifier, address _votebook) public initializer {
        governableContract = Governable(_governableContract);
        proposalVerifier = IProposalVerifier(_proposalVerifier);
        votebook = VotesBookKeeper(_votebook);
    }

    /// @notice Get the proposal params of a given proposal.
    /// @param proposalID The ID of the proposal.
    /// @return pType The type of the proposal.
    /// @return executable The execution type of the proposal.
    /// @return minVotes The minimum number of votes required.
    /// @return minAgreement The minimum agreement required.
    /// @return opinionScales The opinion scales.
    /// @return options The options.
    /// @return proposalContract The address of the proposal contract.
    /// @return votingStartTime The start time of the voting.
    /// @return votingMinEndTime The minimum end time of the voting.
    /// @return votingMaxEndTime The maximum end time of the voting.
    function proposalParams(uint256 proposalID) public view returns (
        uint256 pType,
        Proposal.ExecType executable,
        uint256 minVotes,
        uint256 minAgreement,
        uint256[] memory opinionScales,
        bytes32[] memory options,
        address proposalContract,
        uint256 votingStartTime,
        uint256 votingMinEndTime,
        uint256 votingMaxEndTime
    )
    {
        Proposal.Parameters memory p = _proposals[proposalID].params;
        return (
            p.pType,
            p.executable,
            p.minVotes,
            p.minAgreement,
            p.opinionScales,
            p.options,
            p.proposalContract,
            p.deadlines.votingStartTime,
            p.deadlines.votingMinEndTime,
            p.deadlines.votingMaxEndTime
        );
    }

    /// @notice Get the state of a specific option in a proposal.
    /// @param proposalID The ID of the proposal.
    /// @param optionID The ID of the option.
    /// @return votes Sum of total weight of votes
    /// @return agreementRatio The agreement ratio for the option.
    /// @return agreement The agreement value for the option.
    function proposalOptionState(uint256 proposalID, uint256 optionID) public view returns (uint256 votes, uint256 agreementRatio, uint256 agreement) {
        ProposalState storage prop = _proposals[proposalID];
        LRC.Option storage opt = prop.options[optionID];
        return (opt.votes, LRC.agreementRatio(opt), opt.agreement);
    }

    /// @notice Get the state of a proposal.
    /// @param proposalID The ID of the proposal.
    /// @return winnerOptionID The ID of the winning option.
    /// @return votes Sum of total weight of votes
    /// @return status The status of the proposal.
    function proposalState(uint256 proposalID) public view returns (uint256 winnerOptionID, uint256 votes, ProposalStatus status) {
        ProposalState storage p = _proposals[proposalID];
        return (p.winnerOptionID, p.votes, p.status);
    }

    /// @notice Get the vote details of a specific voter to a specific proposal.
    /// @param from The address of the voter.
    /// @param delegatedTo The address which the voter has delegated their stake to.
    /// @param proposalID The ID of the proposal.
    /// @return weight The weight of the vote.
    /// @return choices The choices of the vote.
    function getVote(address from, address delegatedTo, uint256 proposalID) public view returns (uint256 weight, uint256[] memory choices) {
        Vote memory v = _votes[from][delegatedTo][proposalID];
        return (v.weight, v.choices);
    }

    /// @notice Get the total number of tasks.
    /// @return The total number of tasks.
    function tasksCount() public view returns (uint256) {
        return (tasks.length);
    }

    /// @notice Get the details of a specific task.
    /// @param i The index of the task.
    /// @return active Whether the task is active.
    /// @return assignment The assignment type of the task.
    /// @return proposalID The ID of the proposal associated with the task.
    function getTask(uint256 i) public view returns (bool active, uint256 assignment, uint256 proposalID) {
        Task memory t = tasks[i];
        return (t.active, t.assignment, t.proposalID);
    }

    /// @notice Cast a vote for a proposal.
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param proposalID The ID of the proposal.
    /// @param choices The choices of the vote.
    function vote(address delegatedTo, uint256 proposalID, uint256[] calldata choices) external nonReentrant {
        if (delegatedTo == address(0)) {
            delegatedTo = msg.sender;
        }

        ProposalState storage prop = _proposals[proposalID];

        require(prop.params.proposalContract != address(0), "given proposalID doesn't exist");
        require(prop.status == ProposalStatus.INITIAL, "proposal isn't active");
        require(block.timestamp >= prop.params.deadlines.votingStartTime, "proposal voting hasn't begun");
        require(_votes[msg.sender][delegatedTo][proposalID].weight == 0, "vote already exists");
        require(choices.length == prop.params.options.length, "wrong number of choices");

        uint256 weight = _processNewVote(proposalID, msg.sender, delegatedTo, choices);
        require(weight != 0, "zero weight");
    }

    /// @notice Create a new proposal.
    /// @param proposalContract The address of the proposal contract.
    function createProposal(address proposalContract) external nonReentrant payable {
        require(msg.value == proposalFee, "paid proposal fee is wrong");

        lastProposalID++;
        _createProposal(lastProposalID, proposalContract);
        addTasks(lastProposalID);

        // burn a non-reward part of the proposal fee
        burn(proposalBurntFee);

        emit ProposalCreated(lastProposalID);
    }

    /// @dev Internal function to create a new proposal.
    /// @param proposalID The ID of the proposal.
    /// @param proposalContract The address of the proposal contract.
    function _createProposal(uint256 proposalID, address proposalContract) internal {
        require(proposalContract != address(0), "empty proposal address");
        IProposal p = IProposal(proposalContract);
        // capture the parameters once to ensure that contract will not return different values
        uint256 pType = p.pType();
        Proposal.ExecType executable = p.executable();
        uint256 minVotes = p.minVotes();
        uint256 minAgreement = p.minAgreement();
        uint256[] memory opinionScales = p.opinionScales();
        uint256 votingStartTime = p.votingStartTime();
        uint256 votingMinEndTime = p.votingMinEndTime();
        uint256 votingMaxEndTime = p.votingMaxEndTime();
        bytes32[] memory options = p.options();
        // check the parameters and contract
        require(options.length != 0, "proposal options are empty");
        require(options.length <= maxOptions, "too many options");
        proposalVerifier.verifyProposalParams(
            pType,
            executable,
            minVotes,
            minAgreement,
            opinionScales,
            votingStartTime,
            votingMinEndTime,
            votingMaxEndTime
        );
        proposalVerifier.verifyProposalContract(pType, proposalContract);
        // save the parameters
        ProposalState storage prop = _proposals[proposalID];
        prop.params.pType = pType;
        prop.params.executable = executable;
        prop.params.minVotes = minVotes;
        prop.params.minAgreement = minAgreement;
        prop.params.opinionScales = opinionScales;
        prop.params.proposalContract = proposalContract;
        prop.params.deadlines.votingStartTime = votingStartTime;
        prop.params.deadlines.votingMinEndTime = votingMinEndTime;
        prop.params.deadlines.votingMaxEndTime = votingMaxEndTime;
        prop.params.options = options;
    }

    /// @notice Cancel a proposal if no votes have been cast - Only the proposal contract can cancel the proposal.
    /// @param proposalID The ID of the proposal.
    function cancelProposal(uint256 proposalID) external nonReentrant {
        ProposalState storage prop = _proposals[proposalID];
        require(prop.params.proposalContract != address(0), "given proposalID doesn't exist");
        require(prop.status == ProposalStatus.INITIAL, "proposal isn't active");
        require(prop.votes == 0, "voting has already begun");
        require(msg.sender == prop.params.proposalContract, "sender not the proposal address");

        prop.status = ProposalStatus.CANCELED;
        emit ProposalCanceled(proposalID);
    }

    /// @notice Handle a specified range of tasks.
    /// @dev Emits TasksHandled event.
    /// @param startIdx The starting index of the tasks.
    /// @param quantity The number of tasks to handle.
    function handleTasks(uint256 startIdx, uint256 quantity) external nonReentrant {
        uint256 handled = 0;
        uint256 i;
        for (i = startIdx; i < tasks.length && i < startIdx + quantity; i++) {
            if (handleTask(i)) {
                handled += 1;
            }
        }

        require(handled != 0, "no tasks handled");

        emit TasksHandled(startIdx, i, handled);
        // reward the sender
        (bool success, ) = payable(msg.sender).call{value: handled * taskHandlingReward}("");
        require(success, "transfer failed");
    }

    /// @notice Clean up inactive tasks.
    /// @dev Emits TasksErased event.
    /// @param quantity The number of tasks to clean up.
    function tasksCleanup(uint256 quantity) external nonReentrant {
        uint256 erased;
        for (erased = 0; tasks.length > 0 && erased < quantity; erased++) {
            if (!tasks[tasks.length - 1].active) {
                tasks.pop();
            } else {
                break;
                // stop when first active task was met
            }
        }
        require(erased > 0, "no tasks erased");
        emit TasksErased(erased);
        // reward the sender
        (bool success, ) = payable(msg.sender).call{value: erased * taskErasingReward}("");
        require(success, "transfer failed");
    }

    /// @dev Handle a single specific task.
    /// @param taskIdx The index of the task.
    /// @return handled Whether the task was handled.
    function handleTask(uint256 taskIdx) internal returns (bool handled) {
        require(taskIdx < tasks.length, "incorrect task index");
        Task storage task = tasks[taskIdx];
        if (!task.active) {
            return false;
        }
        handled = handleTaskAssignments(tasks[taskIdx].proposalID, task.assignment);
        if (handled) {
            task.active = false;
        }
        return handled;
    }

    /// @dev Handle task for a proposal by its assignment.
    /// @param proposalID The ID of the proposal.
    /// @param assignment The assignment type.
    /// @return handled Whether the task was handled.
    function handleTaskAssignments(uint256 proposalID, uint256 assignment) internal returns (bool handled) {
        ProposalState storage prop = _proposals[proposalID];
        if (prop.status != ProposalStatus.INITIAL) {
            // deactivate all tasks for non-active proposals
            return true;
        }
        if (assignment == TASK_VOTING) {
            return handleVotingTask(proposalID, prop);
        }
        return false;
    }

    /// @dev Handle voting tasks for a proposal with TASK_VOTING assignment.
    /// @dev Emits ProposalResolved or ProposalRejected event depending of the fate of the task.
    /// @param proposalID The ID of the proposal.
    /// @param prop The state of the proposal.
    /// @return handled Whether the task was handled.
    function handleVotingTask(uint256 proposalID, ProposalState storage prop) internal returns (bool handled) {
        uint256 minVotesAbs = minVotesAbsolute(governableContract.getTotalWeight(), prop.params.minVotes);
        bool must = block.timestamp >= prop.params.deadlines.votingMaxEndTime;
        bool may = block.timestamp >= prop.params.deadlines.votingMinEndTime && prop.votes >= minVotesAbs;
        if (!must && !may) {
            return false;
        }
        (bool proposalResolved, uint256 winnerID) = _calculateVotingTally(prop);
        if (proposalResolved) {
            (bool ok, bool expired) = executeProposal(prop, winnerID);
            if (!ok) {
                return false;
            }
            if (!expired) {
                prop.status = ProposalStatus.RESOLVED;
                prop.winnerOptionID = winnerID;
                emit ProposalResolved(proposalID);
            } else {
                prop.status = ProposalStatus.EXECUTION_EXPIRED;
                emit ProposalExecutionExpired(proposalID);
            }
        } else {
            prop.status = ProposalStatus.FAILED;
            emit ProposalRejected(proposalID);
        }
        return true;
    }

    /// @dev Execute a proposal.
    /// @param prop The state of the proposal.
    /// @param winnerOptionID The ID of the winning option.
    /// @return success Whether the execution was successful.
    /// @return expired Whether the execution period has expired.
    function executeProposal(ProposalState storage prop, uint256 winnerOptionID) internal returns (bool, bool) {
        bool executable = prop.params.executable == Proposal.ExecType.CALL || prop.params.executable == Proposal.ExecType.DELEGATECALL;
        if (!executable) {
            return (true, false);
        }

        bool executionExpired = block.timestamp > prop.params.deadlines.votingMaxEndTime + maxExecutionPeriod;
        if (executionExpired) {
            // protection against proposals which revert or consume too much gas
            return (true, true);
        }
        address propAddr = prop.params.proposalContract;
        bool success = true;
        if (prop.params.executable == Proposal.ExecType.CALL) {
            IProposal(propAddr).executeCall(winnerOptionID);
        } else {
            // Call must be delegated
            (success, ) = propAddr.delegatecall(
                abi.encodeCall(IProposal(propAddr).executeDelegateCall,
                    (propAddr, winnerOptionID)
                ));
        }
        return (success, false);
    }

    /// @notice Calculates votes options and finds the winner.
    /// @param proposalID The ID of the proposal.
    /// @return proposalResolved Whether the proposal is resolved.
    /// @return winnerID The ID of the winning option.
    /// @return votes The total number of votes.
    function calculateVotingTally(uint256 proposalID) external view returns (bool proposalResolved, uint256 winnerID, uint256 votes) {
        ProposalState storage prop = _proposals[proposalID];
        (proposalResolved, winnerID) = _calculateVotingTally(prop);
        return (proposalResolved, winnerID, prop.votes);
    }

    /// @dev internal function for calculating votes options and finding the winner.
    /// @param prop The state of the proposal.
    /// @return proposalResolved Whether the proposal is resolved.
    /// @return winnerID The ID of the winning option.
    function _calculateVotingTally(ProposalState storage prop) internal view returns (bool, uint256) {
        uint256 minVotesAbs = minVotesAbsolute(governableContract.getTotalWeight(), prop.params.minVotes);
        uint256 mostAgreement = 0;
        uint256 winnerID = prop.params.options.length;
        if (prop.votes < minVotesAbs) {
            return (false, winnerID);
        }
        for (uint256 i = 0; i < prop.params.options.length; i++) {
            uint256 optionID = i;
            uint256 agreement = LRC.agreementRatio(prop.options[optionID]);

            if (agreement < prop.params.minAgreement) {
                // critical resistance against this option
                continue;
            }

            if (mostAgreement == 0 || agreement > mostAgreement) {
                mostAgreement = agreement;
                winnerID = i;
            }
        }

        return (winnerID != prop.params.options.length, winnerID);
    }

    /// @notice Cancel a vote for a proposal.
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param proposalID The ID of the proposal.
    function cancelVote(address delegatedTo, uint256 proposalID) external nonReentrant {
        if (delegatedTo == address(0)) {
            delegatedTo = msg.sender;
        }
        Vote memory v = _votes[msg.sender][delegatedTo][proposalID];
        require(v.weight != 0, "doesn't exist");
        require(_proposals[proposalID].status == ProposalStatus.INITIAL, "proposal isn't active");
        _cancelVote(msg.sender, delegatedTo, proposalID);
    }

    /// @dev internal function for canceling a vote.
    /// @dev Emits VoteCanceled event.
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param proposalID The ID of the proposal.
    function _cancelVote(address voter, address delegatedTo, uint256 proposalID) internal {
        Vote storage v = _votes[voter][delegatedTo][proposalID];
        if (v.weight == 0) {
            return;
        }

        if (voter != delegatedTo) {
            unOverrideDelegationWeight(delegatedTo, proposalID, v.weight);
        }

        removeChoicesFromProp(proposalID, v.choices, v.weight);
        delete _votes[voter][delegatedTo][proposalID];

        if (address(votebook) != address(0)) {
            votebook.onVoteCanceled(voter, delegatedTo, proposalID);
        }

        emit VoteCanceled(voter, delegatedTo, proposalID);
    }

    /// @dev Cast a vote for a proposal.
    /// @dev Emits Voted event.
    /// @param proposalID The ID of the proposal.
    /// @param voter The address of the voter.
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param choices The choices of the vote.
    /// @param weight The weight of the vote.
    function makeVote(uint256 proposalID, address voter, address delegatedTo, uint256[] memory choices, uint256 weight) internal {
        _votes[voter][delegatedTo][proposalID] = Vote(weight, choices);
        addChoicesToProp(proposalID, choices, weight);
        if (address(votebook) != address(0)) {
            votebook.onVoted(voter, delegatedTo, proposalID);
        }
        emit Voted(voter, delegatedTo, proposalID, choices, weight);
    }

    /// @dev Process a new vote for a proposal.
    /// @param proposalID The ID of the proposal.
    /// @param voterAddr The address of the voter.
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param choices The choices of the vote.
    /// @return The weight of the vote.
    function _processNewVote(uint256 proposalID, address voterAddr, address delegatedTo, uint256[] memory choices) internal returns (uint256) {
        if (delegatedTo == voterAddr) {
            // voter isn't a delegator
            uint256 weight = governableContract.getReceivedWeight(voterAddr);
            uint256 overridden = overriddenWeight[voterAddr][proposalID];
            if (weight > overridden) {
                weight -= overridden;
            } else {
                weight = 0;
            }
            if (weight == 0) {
                return 0;
            }
            makeVote(proposalID, voterAddr, voterAddr, choices, weight);
            return weight;
        } else {
            if (_votes[delegatedTo][delegatedTo][proposalID].choices.length > 0) {
                // recount vote from delegatedTo
                // Needed only in a case if delegatedTo's received weight has changed without calling recountVote
                _recountVote(delegatedTo, delegatedTo, proposalID);
            }
            // votes through one of delegations, overrides previous vote of "delegatedTo" (if any)
            uint256 delegatedWeight = governableContract.getWeight(voterAddr, delegatedTo);
            // reduce weight of vote of "delegatedTo" (current vote or any future vote)
            overrideDelegationWeight(delegatedTo, proposalID, delegatedWeight);
            if (delegatedWeight == 0) {
                return 0;
            }
            // make own vote
            makeVote(proposalID, voterAddr, delegatedTo, choices, delegatedWeight);
            return delegatedWeight;
        }
    }

    /// @notice Recount a votes weight for a proposal.
    /// @param voterAddr The address of the voter.
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param proposalID The ID of the proposal.
    function recountVote(address voterAddr, address delegatedTo, uint256 proposalID) external nonReentrant {
        Vote storage v = _votes[voterAddr][delegatedTo][proposalID];
        Vote storage vSuper = _votes[delegatedTo][delegatedTo][proposalID];
        require(v.choices.length > 0, "doesn't exist");
        require(_proposals[proposalID].status == ProposalStatus.INITIAL, "proposal isn't active");
        uint256 beforeSelf = v.weight;
        uint256 beforeSuper = vSuper.weight;
        _recountVote(voterAddr, delegatedTo, proposalID);
        uint256 afterSelf = v.weight;
        uint256 afterSuper = vSuper.weight;
        // check that some weight has changed due to recounting
        require(beforeSelf != afterSelf || beforeSuper != afterSuper, "nothing changed");
    }

    /// @dev internal function for recounting votes.
    /// @param voterAddr The address of the voter.
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param proposalID The ID of the proposal.
    /// @return The weight of the vote.
    function _recountVote(address voterAddr, address delegatedTo, uint256 proposalID) internal returns (uint256) {
        uint256[] memory origChoices = _votes[voterAddr][delegatedTo][proposalID].choices;
        // cancel previous vote
        _cancelVote(voterAddr, delegatedTo, proposalID);
        // re-make vote
        return _processNewVote(proposalID, voterAddr, delegatedTo, origChoices);
    }

    /// @dev Override the delegation weight for a proposal.
    /// @dev Emits VoteWeightOverridden event.
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param proposalID The ID of the proposal.
    /// @param weight The weight of the vote.
    function overrideDelegationWeight(address delegatedTo, uint256 proposalID, uint256 weight) internal {
        uint256 overridden = overriddenWeight[delegatedTo][proposalID];
        overridden = overridden + weight;
        overriddenWeight[delegatedTo][proposalID] = overridden;
        Vote storage v = _votes[delegatedTo][delegatedTo][proposalID];
        if (v.choices.length > 0) {
            v.weight = v.weight - weight;
            removeChoicesFromProp(proposalID, v.choices, weight);
        }
        emit VoteWeightOverridden(delegatedTo, weight);
    }

    /// @dev Un-override the delegation weight for a proposal.
    /// @dev Emits VoteWeightUnOverridden event.
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param proposalID The ID of the proposal.
    /// @param weight The weight of the vote.
    function unOverrideDelegationWeight(address delegatedTo, uint256 proposalID, uint256 weight) internal {
        uint256 overridden = overriddenWeight[delegatedTo][proposalID];
        overridden = overridden - weight;
        overriddenWeight[delegatedTo][proposalID] = overridden;
        Vote storage v = _votes[delegatedTo][delegatedTo][proposalID];
        if (v.choices.length > 0) {
            v.weight = v.weight + weight;
            addChoicesToProp(proposalID, v.choices, weight);
        }
        emit VoteWeightUnOverridden(delegatedTo, weight);
    }

    /// @dev Add choices to a proposal.
    /// @param proposalID The ID of the proposal.
    /// @param choices The choices to be added.
    /// @param weight The weight of the vote.
    function addChoicesToProp(uint256 proposalID, uint256[] memory choices, uint256 weight) internal {
        ProposalState storage prop = _proposals[proposalID];

        prop.votes = prop.votes + weight;

        for (uint256 i = 0; i < prop.params.options.length; i++) {
            prop.options[i].addVote(choices[i], weight, prop.params.opinionScales);
        }
    }

    /// @dev Remove choices from a proposal.
    /// @param proposalID The ID of the proposal.
    /// @param choices The choices to be removed.
    /// @param weight The weight of the vote.
    function removeChoicesFromProp(uint256 proposalID, uint256[] memory choices, uint256 weight) internal {
        ProposalState storage prop = _proposals[proposalID];

        prop.votes = prop.votes - weight;

        for (uint256 i = 0; i < prop.params.options.length; i++) {
            prop.options[i].removeVote(choices[i], weight, prop.params.opinionScales);
        }
    }

    /// @dev Add a task for a proposal.
    /// @param proposalID The ID of the proposal.
    function addTasks(uint256 proposalID) internal {
        tasks.push(Task(true, TASK_VOTING, proposalID));
    }

    /// @dev Burn a specified amount of tokens.
    /// @param amount The amount of tokens to burn.
    function burn(uint256 amount) internal {
        (bool success, ) = payable(address(0)).call{value: amount}("");
        require(success, "transfer failed");
    }

    /// @dev Sanitize the winner ID of a resolved proposal.
    /// @param proposalID The ID of the proposal.
    function sanitizeWinnerID(uint256 proposalID) external {
        ProposalState storage prop = _proposals[proposalID];
        require(prop.status == ProposalStatus.RESOLVED, "proposal isn't resolved");
        require(prop.params.executable == Proposal.ExecType.NONE, "proposal is executable");
        require(prop.winnerOptionID == 0, "winner ID is correct");
        (, prop.winnerOptionID) = _calculateVotingTally(prop);
    }

    /// @dev Upgrade the votebook contract.
    /// @param _votebook The address of the new votebook contract.
    function upgrade(address _votebook) external {
        require(address(votebook) == address(0), "already set");
        votebook = VotesBookKeeper(_votebook);
        // erase leftovers from upgradeability proxy
        assembly {
            sstore(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103, 0)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, 0)
        }
    }
}
