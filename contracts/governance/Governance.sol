pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Constants.sol";
import "./Governable.sol";
// import "./Proposal.sol";
import "./SoftwareUpgradeProposal.sol";
import "./GovernanceSettings.sol";
import "./AbstractProposal.sol";
import "./LRC.sol";
import "./IProposalFactory.sol";
import "../common/ImplementationValidator.sol";

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

    struct ProposalTimeline {
        uint256 votingStartTime;
        uint256 votingEndTime;
    }

    struct ProposalDescription {
        ProposalTimeline deadlines;
        string description;
        uint256 id;
        uint256 requiredVotes;
        uint256 status;
        mapping(uint256 => LRC.LrcOption) options;
        uint256[] optionIDs;
        uint256 lastOptionID;
        uint256 chosenOption;
        uint256 totalWeight;
        uint8 propType;
        address proposalContract;
    }

    struct Task {
        bool active;
        uint256 assignment;
        uint256 proposalID;
    }

    Governable governableContract;
    ImplementationValidator implementationValidator;
    IProposalFactory proposalFactory;
    uint256 public lastProposalID;
    Task[] public tasks;
    bytes4 abstractProposalInterfaceId;

    mapping(uint256 => ProposalDescription) proposals;
    mapping(uint256 => ProposalTimeline) proposalDeadlines; // proposal ID to Deadline
    mapping(address => mapping(uint256 => uint256)) public overriddenWeight; // sender address to proposal id to weight
    mapping(address => mapping(address => mapping(uint256 => Vote))) public votes; // voter, delegationReceiver, proposalID -> Vote

    event ProposalIsCreated(uint256 proposalID);
    event ProposalIsResolved(uint256 proposalID);
    event RejectedProposal(uint256 proposalID);
    event StartedProposalVoting(uint256 proposalID);
    event TasksHandled(uint256 startIdx, uint256 endIdx, uint256 handled);
    event TasksErased(uint256 quantity);
    event ResolvedProposal(uint256 proposalID);
    event ImplementedProposal(uint256 proposalID);
    event DeadlineRemoved(uint256 deadline);
    event DeadlineAdded(uint256 deadline);
    event GovernableContractSet(address addr);
    event SoftwareVersionAdded(string version, address addr);
    event VoteWeightOverridden(address voter, uint256 diff);
    event VoteWeightUnOverridden(address voter, uint256 diff);
    event Voted(address voter, address delegatedTo, uint256 proposalID, uint256[] choices, uint256 weight);

    constructor (address _governableContract, address _proposalFactory) public {
        governableContract = Governable(_governableContract);
        proposalFactory = IProposalFactory(_proposalFactory);
    }

    function getProposalStatus(uint256 proposalID) public view returns (uint256) {
        ProposalDescription storage prop = proposals[proposalID];
        return (prop.status);
    }

    function getTasksCount() public view returns (uint256) {
        return (tasks.length);
    }

    function getProposalDescription(uint256 proposalID) public view 
    returns (
        string memory description,
        uint256 requiredVotes,
        uint256 status,
        uint256 chosenOption,
        uint256 totalWeight,
        address proposalContract) {
        ProposalDescription storage prop = proposals[proposalID];

        return (
            prop.description,
            prop.requiredVotes,
            prop.status,
            prop.chosenOption,
            prop.totalWeight,
            prop.proposalContract
        );
    }

    function vote(address delegatedTo, uint256 proposalID, uint256[] memory choices) internal {
        if (delegatedTo == address(0)) {
            delegatedTo = msg.sender;
        }

        ProposalDescription storage prop = proposals[proposalID];

        require(prop.id == proposalID, "proposal with a given id doesnt exist");
        require(statusVoting(prop.status), "proposal is not at voting period");
        require(votes[msg.sender][delegatedTo][proposalID].weight == 0, "vote already exists");
        require(choices.length == prop.optionIDs.length, "incorrect choices");

        require(_processNewVote(prop.id, msg.sender, delegatedTo, choices) != 0, "zero weight");
    }

    function createProposal(address proposalContract) public payable {
        validateProposalContract(proposalContract);
        require(msg.value == proposalFee(), "paid proposal fee is wrong");
        require (proposalFactory.canVoteForProposal(proposalContract), "cannot vote for a given proposal");

        AbstractProposal proposal = AbstractProposal(proposalContract);
        bytes32[] memory options = proposal.getOptions();
        require(options.length != 0, "proposal options is empty - nothing to vote for");

        lastProposalID++;
        ProposalDescription storage prop = proposals[lastProposalID];
        prop.id = lastProposalID;
        prop.status = setStatusVoting(0);
        prop.requiredVotes = minimumVotesRequired(governableContract.getTotalWeight());
        for (uint256 i = 0; i < options.length; i++) {
            prop.lastOptionID++;
            LRC.LrcOption storage option = prop.options[prop.lastOptionID];
            option.description = options[i];
            // option.description = bytes32ToString(choices[i]);
            prop.optionIDs.push(prop.lastOptionID);
        }
        prop.proposalContract = proposalContract;
        votingDeadlines(lastProposalID);
        addTasks(lastProposalID);
        proposalFactory.setProposalIsConsidered(proposalContract);

        // burn the proposal fee
        burn(msg.value);

        emit ProposalIsCreated(lastProposalID);
    }

    function validateProposalContract(address proposalContract) public {
        AbstractProposal proposal = AbstractProposal(proposalContract);
        require(proposal.supportsInterface(abstractProposalInterfaceId), "address does not implement proposal interface");
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
                break; // stop when first active task was met
            }
        }
        require(erased > 0, "no tasks erased");
        emit TasksErased(erased);
    }

    // handleTask calls handleTaskAssignments and marks task as inactive if it was handled
    function handleTask(uint256 taskIdx) internal returns(bool handled) {
        require(taskIdx < tasks.length, "incorrect task index");
        Task storage task = tasks[taskIdx];
        if (!task.active) {
            return false;
        }
        ProposalDescription storage prop = proposals[tasks[taskIdx].proposalID];
        handled = handleTaskAssignments(prop, task.assignment);
        if (handled) {
            task.active = false;
        }
        return handled;
    }

    // handleTaskAssignments iterates through assignment types and calls a specific handler
    function handleTaskAssignments(ProposalDescription storage prop, uint256 assignment) internal returns(bool handled) {
        if (assignment == TASK_VOTING) {
            return handleVotingTask(prop);
        }
        return false;
    }

    // handleVotingTask handles only TASK_VOTING
    function handleVotingTask(ProposalDescription storage prop) internal returns (bool handled) {
        bool ready = statusVoting(prop.status) &&
        (prop.totalWeight >= prop.requiredVotes || block.timestamp >= prop.deadlines.votingEndTime);
        if (!ready) {
            return false;
        }
        (bool proposalAccepted, uint256 winnerId) = calculateVotingResult(prop.id);
        if (proposalAccepted) {
            resolveProposal(prop.id, winnerId);
            emit ResolvedProposal(prop.id);
        } else {
            prop.status = failStatus(prop.status);
            emit RejectedProposal(prop.id);
        }
        return true;
    }

    function proceedToVoting(uint256 proposalID) internal {
        ProposalDescription storage prop = proposals[proposalID];
        prop.deadlines.votingStartTime = block.timestamp;
        prop.deadlines.votingEndTime = block.timestamp + votingPeriod();
        prop.status = setStatusVoting(prop.status);
        emit StartedProposalVoting(proposalID);
    }

    function resolveProposal(uint256 proposalID, uint256 winnerOptionId) internal {
        ProposalDescription storage prop = proposals[proposalID];
        require(statusVoting(prop.status), "proposal is not at voting period");

        if (prop.propType == typeExecutable()) {
            address propAddr = prop.proposalContract;
            propAddr.delegatecall(abi.encodeWithSignature("execute(uint256)", winnerOptionId));
        }

        prop.status = setStatusAccepted(prop.status);
        prop.chosenOption = winnerOptionId;
    }

    function calculateVotingResult(uint256 proposalID) internal returns(bool, uint256) {
        ProposalDescription storage prop = proposals[proposalID];
        uint256 leastResistance;
        uint256 winnerId;
        for (uint256 i = 0; i < prop.optionIDs.length; i++) {
            uint256 optionID = prop.optionIDs[i];
            prop.options[optionID].recalculate();
            uint256 arc = prop.options[optionID].arc;

            if (prop.options[optionID].dw > _maximumlPossibleDesignation) {
                continue;
            }

            if (leastResistance == 0) {
                leastResistance = arc;
                winnerId = i;
                continue;
            }

            if (arc <= _maximumlPossibleResistance && arc <= leastResistance) {
                leastResistance = arc;
                winnerId = i;
                continue;
            }
        }

        return (leastResistance != 0, winnerId);
    }

    function cancelVote(uint256 proposalID, address delegatedTo) public {
        if (delegatedTo == address(0)) {
            delegatedTo = msg.sender;
        }
        Vote memory v = votes[msg.sender][delegatedTo][proposalID];
        require(v.weight != 0, "doesn't exist");
        _cancelVote(proposalID, msg.sender, delegatedTo);
    }

    function _cancelVote(uint256 proposalID, address voteAddr, address delegatedTo) internal {
        Vote memory v = votes[voteAddr][delegatedTo][proposalID];
        if (v.weight == 0) {
            return;
        }

        if (voteAddr != delegatedTo) {
            unOverrideDelegationWeight(proposalID, voteAddr, v.weight);
        }

        removeChoicesFromProp(proposalID, v.choices, v.weight);
        delete votes[voteAddr][delegatedTo][proposalID];
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
        ProposalDescription storage prop = proposals[proposalID];

        require(choices.length == prop.optionIDs.length, "incorrect choices");

        prop.totalWeight += weight;

        for (uint256 i = 0; i < prop.optionIDs.length; i++) {
            uint256 optionID = prop.optionIDs[i];
            prop.options[optionID].addVote(choices[i], weight);
        }
    }

    function removeChoicesFromProp(uint256 proposalID, uint256[] memory choices, uint256 weight) internal {
        ProposalDescription storage prop = proposals[proposalID];

        require(choices.length == prop.optionIDs.length, "incorrect choices");

        prop.totalWeight -= weight;

        for (uint256 i = 0; i < prop.optionIDs.length; i++) {
            uint256 optionID = prop.optionIDs[i];
            prop.options[optionID].removeVote(choices[i], weight);
        }
    }

    function votingDeadlines(uint256 proposalID) internal {
        ProposalDescription storage prop = proposals[proposalID];
        prop.deadlines.votingStartTime = block.timestamp;
        prop.deadlines.votingEndTime = block.timestamp + votingPeriod();
    }

    function addTasks(uint256 proposalID) internal {
        tasks.push(Task(true, proposalID, TASK_VOTING));
    }

    function burn(uint256 amount) internal {
        address(0).transfer(amount);
    }
}
