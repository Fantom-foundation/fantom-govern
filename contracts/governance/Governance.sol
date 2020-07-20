pragma solidity ^0.5.0;

import "../common/SafeMath.sol";
import "../model/Governable.sol";
import "../proposal/IProposal.sol";
import "../proposal/SoftwareUpgradeProposal.sol";
import "./IProposalVerifier.sol";
import "./Proposal.sol";
import "./Constants.sol";
import "./GovernanceSettings.sol";
import "./LRC.sol";

// TODO:
// Add lib to prevent reentrance
// Add more tests
// Add LRC voting and calculation
contract Governance is GovernanceSettings {
    using SafeMath for uint256;
    using LRC for LRC.LrcOption;

    struct Vote {
        uint256 weight;
        uint256[] choices;
    }

    struct ProposalState {
        Proposal.Parameters params;

        mapping(uint256 => LRC.LrcOption) options;
        uint256[] optionIDs;
        uint256 lastOptionID;
        uint256 winnerOptionID;

        uint256 status;
        uint256 votesWeight;
    }

    struct Task {
        bool active;
        uint256 assignment;
        uint256 proposalID;
    }

    Governable governableContract;
    IProposalVerifier proposalVerifier;
    uint256 public lastProposalID;
    Task[] public tasks;
    bytes4 abstractProposalInterfaceId;

    mapping(uint256 => ProposalState) proposals;
    mapping(address => mapping(uint256 => uint256)) public overriddenWeight; // voter address, proposalID -> weight
    mapping(address => mapping(address => mapping(uint256 => Vote))) public votes; // voter, delegationReceiver, proposalID -> Vote

    event ProposalCreated(uint256 proposalID);
    event ProposalResolved(uint256 proposalID);
    event ProposalRejected(uint256 proposalID);
    event ProposalCanceled(uint256 proposalID);
    event ProposalExecutionExpired(uint256 proposalID);
    event TasksHandled(uint256 startIdx, uint256 endIdx, uint256 handled);
    event TasksErased(uint256 quantity);
    event VoteWeightOverridden(address voter, uint256 diff);
    event VoteWeightUnOverridden(address voter, uint256 diff);
    event Voted(address voter, address delegatedTo, uint256 proposalID, uint256[] choices, uint256 weight);
    event VoteCanceled(address voter, address delegatedTo, uint256 proposalID);

    constructor (address _governableContract, address _proposalVerifier) public {
        governableContract = Governable(_governableContract);
        proposalVerifier = IProposalVerifier(_proposalVerifier);
    }

    function getProposalStatus(uint256 proposalID) public view returns (uint256) {
        ProposalState storage prop = proposals[proposalID];
        return (prop.status);
    }

    function getTasksCount() public view returns (uint256) {
        return (tasks.length);
    }

    function vote(address delegatedTo, uint256 proposalID, uint256[] memory choices) internal {
        if (delegatedTo == address(0)) {
            delegatedTo = msg.sender;
        }

        ProposalState storage prop = proposals[proposalID];

        require(prop.params.proposalContract != address(0), "proposal with a given ID doesnt exist");
        require(isInitialStatus(prop.status), "proposal isn't active");
        require(block.timestamp >= prop.params.deadlines.votingMinEndTime, "proposal voting has't begun");
        require(votes[msg.sender][delegatedTo][proposalID].weight == 0, "vote already exists");
        require(choices.length == prop.optionIDs.length, "wrong number of choices");

        uint256 weight = _processNewVote(proposalID, msg.sender, delegatedTo, choices);
        require(weight != 0, "zero weight");
    }

    function createProposal(address proposalContract) public payable {
        require(msg.value == proposalFee(), "paid proposal fee is wrong");

        lastProposalID++;
        _createProposal(lastProposalID, proposalContract);
        addTasks(lastProposalID);

        // burn the proposal fee
        burn(msg.value);

        emit ProposalCreated(lastProposalID);
    }

    function _createProposal(uint256 proposalID, address proposalContract) internal {
        require(proposalContract != address(0), "empty proposal address");
        IProposal p = IProposal(proposalContract);
        // capture the parameters once to ensure that contract will not return different values
        uint256 pType = p.pType();
        bool executable = p.executable();
        uint256 minVotes = p.minVotes();
        uint256 votingStartTime = p.votingStartTime();
        uint256 votingMinEndTime = p.votingMinEndTime();
        uint256 votingMaxEndTime = p.votingMaxEndTime();
        bytes32[] memory options = p.options();
        // check the parameters and code
        require(options.length != 0, "proposal options are empty - nothing to vote for");
        require(options.length <= maxOptions(), "too many options");
        bool ok;
        ok = proposalVerifier.verifyProposalParams(pType, executable, minVotes, votingStartTime, votingMinEndTime, votingMaxEndTime);
        require(ok, "proposal parameters failed validation");
        ok = proposalVerifier.verifyProposalCode(pType, proposalContract);
        require(ok, "proposal code failed validation");
        // save the parameters
        ProposalState storage prop = proposals[proposalID];
        prop.params.pType = pType;
        prop.params.executable = executable;
        prop.params.minVotes = minVotes;
        prop.params.proposalContract = proposalContract;
        prop.params.deadlines.votingStartTime = votingStartTime;
        prop.params.deadlines.votingMinEndTime = votingMinEndTime;
        prop.params.deadlines.votingMaxEndTime = votingMaxEndTime;
        for (uint256 i = 0; i < options.length; i++) {
            prop.lastOptionID++;
            LRC.LrcOption storage option = prop.options[prop.lastOptionID];
            option.name = options[i];
            prop.optionIDs.push(prop.lastOptionID);
        }
    }

    // cancelProposal cancels the proposal if no one managed to vote yet
    // must be sent from the proposal contract
    function cancelProposal(uint256 proposalID) public {
        ProposalState storage prop = proposals[proposalID];
        require(prop.params.proposalContract != address(0), "proposal with a given ID doesnt exist");
        require(isInitialStatus(prop.status), "proposal isn't active");
        require(prop.votesWeight == 0, "voting has already begun");
        require(msg.sender == prop.params.proposalContract, "must be sent from the proposal contract");

        prop.status = statusCanceled();
        emit ProposalCanceled(proposalID);
    }

    // handleTasks triggers proposal deadlines processing for a specified range of tasks
    function handleTasks(uint256 startIdx, uint256 quantity) public {
        uint256 handled = 0;
        uint256 i;
        for (i = startIdx; i < tasks.length && i < startIdx + quantity; i++) {
            if (handleTask(i)) {
                handled += 1;
            }
        }

        require(handled != 0, "no tasks handled");

        emit TasksHandled(startIdx, i, handled);
    }

    // tasksCleanup erases inactive (handled) tasks backwards until an active task is met
    function tasksCleanup(uint256 quantity) public {
        uint256 erased;
        for (erased = 0; tasks.length > 0 && erased < quantity; erased++) {
            if (!tasks[tasks.length - 1].active) {
                tasks.length--;
            } else {
                break;
                // stop when first active task was met
            }
        }
        require(erased > 0, "no tasks erased");
        emit TasksErased(erased);
    }

    // handleTask calls handleTaskAssignments and marks task as inactive if it was handled
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

    // handleTaskAssignments iterates through assignment types and calls a specific handler
    function handleTaskAssignments(uint256 proposalID, uint256 assignment) internal returns (bool handled) {
        ProposalState storage prop = proposals[proposalID];
        if (!isInitialStatus(prop.status)) {
            return true;
            // deactivate all tasks for non-active proposals
        }
        if (assignment == TASK_VOTING) {
            return handleVotingTask(proposalID, prop);
        }
        return false;
    }

    // handleVotingTask handles only TASK_VOTING
    function handleVotingTask(uint256 proposalID, ProposalState storage prop) internal returns (bool handled) {
        bool ready = block.timestamp >= prop.params.deadlines.votingMinEndTime &&
        (prop.votesWeight >= prop.params.minVotes || block.timestamp >= prop.params.deadlines.votingMaxEndTime);
        if (!ready) {
            return false;
        }
        (bool proposalResolved, uint256 winnerId) = calculateVotingResult(prop);
        if (proposalResolved) {
            bool expired = resolveProposal(prop, winnerId);
            if (!expired) {
                prop.status = statusResolved();
                emit ProposalResolved(proposalID);
            } else {
                prop.status = statusExecutionExpired();
                emit ProposalExecutionExpired(proposalID);
            }
        } else {
            prop.status = statusFailed();
            emit ProposalRejected(proposalID);
        }
        return true;
    }

    function resolveProposal(ProposalState storage prop, uint256 winnerOptionID) internal returns (bool) {
        prop.winnerOptionID = winnerOptionID;

        bool executionExpired = block.timestamp < prop.params.deadlines.votingMaxEndTime + maxExecutionDuration();
        if (prop.params.executable && executionExpired) {
            // protection against proposals which revert or consume too much gas
            return false;
        }
        if (prop.params.executable && !executionExpired) {
            address propAddr = prop.params.proposalContract;
            (bool success, bytes memory result) = propAddr.delegatecall(abi.encodeWithSignature("execute(address,uint256)", propAddr, winnerOptionID));
            success; // silence unused variable warning
            result;
        }
        return true;
    }

    function calculateVotingResult(ProposalState storage prop) internal returns (bool, uint256) {
        uint256 leastResistance;
        uint256 winnerId = prop.optionIDs.length;
        for (uint256 i = 0; i < prop.optionIDs.length; i++) {
            uint256 optionID = prop.optionIDs[i];
            prop.options[optionID].recalculate();
            uint256 arc = prop.options[optionID].arc;

            if (prop.options[optionID].dw > _maximumPossibleDesignation || arc > _maximumPossibleResistance) {
                // VETO or a critical resistance against this option
                continue;
            }

            if (leastResistance == 0 || arc <= leastResistance) {
                leastResistance = arc;
                winnerId = i;
            }
        }

        return (winnerId != prop.optionIDs.length, winnerId);
    }

    function cancelVote(uint256 proposalID, address delegatedTo) public {
        if (delegatedTo == address(0)) {
            delegatedTo = msg.sender;
        }
        Vote memory v = votes[msg.sender][delegatedTo][proposalID];
        require(v.weight != 0, "doesn't exist");
        _cancelVote(proposalID, msg.sender, delegatedTo);
    }

    function _cancelVote(uint256 proposalID, address voter, address delegatedTo) internal {
        Vote memory v = votes[voter][delegatedTo][proposalID];
        if (v.weight == 0) {
            return;
        }

        if (voter != delegatedTo) {
            unOverrideDelegationWeight(proposalID, voter, v.weight);
        }

        removeChoicesFromProp(proposalID, v.choices, v.weight);
        delete votes[voter][delegatedTo][proposalID];

        emit VoteCanceled(voter, delegatedTo, proposalID);
    }

    function makeVote(uint256 proposalID, address voter, address delegatedTo, uint256[] memory choices, uint256 weight) internal {
        votes[voter][delegatedTo][proposalID] = Vote(weight, choices);
        addChoicesToProp(proposalID, choices, weight);

        emit Voted(voter, delegatedTo, proposalID, choices, weight);
    }

    function _processNewVote(uint256 proposalID, address voterAddr, address delegatedTo, uint256[] memory choices) internal returns (uint256) {
        if (delegatedTo == voterAddr) {
            // voter isn't a delegator
            (uint256 ownVotingWeight, uint256 delegatedMeVotingWeight) = governableContract.getWeight(voterAddr);
            uint256 weight = ownVotingWeight.add(delegatedMeVotingWeight).sub(overriddenWeight[voterAddr][proposalID]);
            if (weight == 0) {
                return 0;
            }
            makeVote(proposalID, voterAddr, voterAddr, choices, weight);
            return weight;
        } else {
            // votes through one of delegations, overrides previous vote of "delegatedTo" (if any)
            uint256 delegatedWeight = governableContract.getDelegatedWeight(voterAddr, delegatedTo);
            if (delegatedWeight == 0) {
                return 0;
            }
            // reduce weight of vote of "delegatedTo" (if any)
            overrideDelegationWeight(proposalID, delegatedTo, delegatedWeight);
            _recountVote(proposalID, delegatedTo, delegatedTo);
            // make own vote
            makeVote(proposalID, voterAddr, delegatedTo, choices, delegatedWeight);
            return delegatedWeight;
        }
    }

    function recountVote(uint256 proposalID, address voterAddr, address delegatedTo) public {
        Vote memory v = votes[voterAddr][delegatedTo][proposalID];
        require(v.weight != 0, "doesn't exist");
        _recountVote(proposalID, voterAddr, delegatedTo);
    }

    function _recountVote(uint256 proposalID, address voterAddr, address delegatedTo) internal returns (uint256) {
        uint256[] memory origChoices = votes[voterAddr][delegatedTo][proposalID].choices;
        // cancel previous vote
        _cancelVote(proposalID, voterAddr, delegatedTo);
        // re-make vote
        return _processNewVote(proposalID, voterAddr, delegatedTo, origChoices);
    }

    function overrideDelegationWeight(uint256 proposalID, address delegatedTo, uint256 weight) internal {
        uint256 overridden = overriddenWeight[delegatedTo][proposalID];
        overridden = overridden.add(weight);
        overriddenWeight[delegatedTo][proposalID] = overridden;
        Vote storage v = votes[delegatedTo][delegatedTo][proposalID];
        if (v.weight != 0) {
            v.weight = v.weight.sub(weight);
            removeChoicesFromProp(proposalID, v.choices, weight);
        }
        emit VoteWeightOverridden(delegatedTo, weight);
    }

    function unOverrideDelegationWeight(uint256 proposalID, address delegatedTo, uint256 weight) internal {
        uint256 overridden = overriddenWeight[delegatedTo][proposalID];
        overridden = overridden.sub(weight);
        overriddenWeight[delegatedTo][proposalID] = overridden;
        Vote storage v = votes[delegatedTo][delegatedTo][proposalID];
        if (v.weight != 0) {
            v.weight = v.weight.add(weight);
            addChoicesToProp(proposalID, v.choices, weight);
        }
        emit VoteWeightUnOverridden(delegatedTo, weight);
    }

    function addChoicesToProp(uint256 proposalID, uint256[] memory choices, uint256 weight) internal {
        ProposalState storage prop = proposals[proposalID];

        require(choices.length == prop.optionIDs.length, "incorrect choices");

        prop.votesWeight += weight;

        for (uint256 i = 0; i < prop.optionIDs.length; i++) {
            uint256 optionID = prop.optionIDs[i];
            prop.options[optionID].addVote(choices[i], weight);
        }
    }

    function removeChoicesFromProp(uint256 proposalID, uint256[] memory choices, uint256 weight) internal {
        ProposalState storage prop = proposals[proposalID];

        require(choices.length == prop.optionIDs.length, "incorrect choices");

        prop.votesWeight -= weight;

        for (uint256 i = 0; i < prop.optionIDs.length; i++) {
            uint256 optionID = prop.optionIDs[i];
            prop.options[optionID].removeVote(choices[i], weight);
        }
    }

    function addTasks(uint256 proposalID) internal {
        tasks.push(Task(true, proposalID, TASK_VOTING));
    }

    function burn(uint256 amount) internal {
        address(0).transfer(amount);
    }
}
