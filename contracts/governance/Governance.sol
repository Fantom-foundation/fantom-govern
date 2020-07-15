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
        uint256 power;
        uint256[] choices;
        address previousDelegation;
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
        uint256 totalVotes;
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
    uint256 public lastProposalId;
    Task[] public tasks;
    bytes4 abstractProposalInterfaceId;

    mapping(uint256 => ProposalDescription) proposals;
    mapping(uint256 => ProposalTimeline) proposalDeadlines; // proposal ID to Deadline
    mapping(address => mapping(uint256 => uint256)) public reducedVotersPower; // sender address to proposal id to power
    mapping(address => mapping(uint256 => Vote)) public votes;

    event ProposalIsCreated(uint256 proposalId);
    event ProposalIsResolved(uint256 proposalId);
    event RejectedProposal(uint256 proposalId);
    event StartedProposalVoting(uint256 proposalId);
    event TasksHandled(uint256 startIdx, uint256 endIdx, uint256 handled);
    event TasksErased(uint256 quantity);
    event ResolvedProposal(uint256 proposalId);
    event ImplementedProposal(uint256 proposalId);
    event DeadlineRemoved(uint256 deadline);
    event DeadlineAdded(uint256 deadline);
    event GovernableContractSet(address addr);
    event SoftwareVersionAdded(string version, address addr);
    event VotersPowerReduced(address voter);
    event UserVoted(address voter, uint256 proposalId, uint256[] choices, uint256 power);

    constructor (address _governableContract, address _proposalFactory) public {
        governableContract = Governable(_governableContract);
        proposalFactory = IProposalFactory(_proposalFactory);
    }

    function getProposalStatus(uint256 proposalId) public view returns (uint256) {
        ProposalDescription storage prop = proposals[proposalId];
        return (prop.status);
    }

    function getTasksCount() public view returns (uint256) {
        return (tasks.length);
    }

    function getProposalDescription(uint256 proposalId) public view 
    returns (
        string memory description,
        uint256 requiredVotes,
        uint256 status,
        uint256 chosenOption,
        uint256 totalVotes,
        address proposalContract) {
        ProposalDescription storage prop = proposals[proposalId];

        return (
            prop.description,
            prop.requiredVotes,
            prop.status,
            prop.chosenOption,
            prop.totalVotes,
            prop.proposalContract
        );
    }

    function vote(uint256 proposalId, uint256[] memory choices) public {
        ProposalDescription storage prop = proposals[proposalId];

        require(prop.id == proposalId, "proposal with a given id doesnt exist");
        require(statusVoting(prop.status), "proposal is not at voting period");
        require(votes[msg.sender][proposalId].power == 0, "this account has already voted. try to cancel a vote if you want to revote");
        require(choices.length == prop.optionIDs.length, "incorrect choices");

        (uint256 ownVotingPower, uint256 delegatedMeVotingPower, uint256 delegatedVotingPower) = accountVotingPower(msg.sender, prop.id);

        if (ownVotingPower != 0) {
            uint256 power = ownVotingPower + delegatedMeVotingPower - reducedVotersPower[msg.sender][proposalId];
            makeVote(proposalId, choices, power);
        }

        if (delegatedVotingPower != 0) {
            address delegatedTo = governableContract.delegatedVotesTo(msg.sender);
            recountVote(proposalId, delegatedTo);
            reduceVotersPower(proposalId, delegatedTo, delegatedVotingPower);
            makeVote(proposalId, choices, delegatedVotingPower);
            votes[msg.sender][proposalId].previousDelegation = delegatedTo;
        }
    }

    function createProposal(address proposalContract) public payable {
        validateProposalContract(proposalContract);
        require(msg.value == proposalFee(), "paid proposal fee is wrong");
        require (proposalFactory.canVoteForProposal(proposalContract), "cannot vote for a given proposal");

        AbstractProposal proposal = AbstractProposal(proposalContract);
        bytes32[] memory options = proposal.getOptions();
        require(options.length != 0, "proposal options is empty - nothing to vote for");

        lastProposalId++;
        ProposalDescription storage prop = proposals[lastProposalId];
        prop.id = lastProposalId;
        prop.status = setStatusVoting(0);
        prop.requiredVotes = minimumVotesRequired(totalVotes(prop.propType));
        for (uint256 i = 0; i < options.length; i++) {
            prop.lastOptionID++;
            LRC.LrcOption storage option = prop.options[prop.lastOptionID];
            option.description = options[i];
            // option.description = bytes32ToString(choices[i]);
            prop.optionIDs.push(prop.lastOptionID);
        }
        prop.proposalContract = proposalContract;
        votingDeadlines(lastProposalId);
        addTasks(lastProposalId);
        proposalFactory.setProposalIsConsidered(proposalContract);

        // burn the proposal fee
        burn(msg.value);

        emit ProposalIsCreated(lastProposalId);
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

    // handleTask calls handleProposalTask and marks task as inactive if it was handled
    function handleTask(uint256 taskIdx) internal returns(bool handled) {
        require(taskIdx < tasks.length, "incorrect task index");
        Task storage task = tasks[taskIdx];
        if (!task.active) {
            return false;
        }
        ProposalDescription storage prop = proposals[tasks[taskIdx].proposalID];
        handled = handleProposalTask(prop, task.assignment);
        if (handled) {
            task.active = false;
        }
        return handled;
    }

    // handleProposalTask iterates through assignment types and calls a specific handler
    function handleProposalTask(ProposalDescription storage prop, uint256 assignment) internal returns(bool handled) {
        if (assignment == TASK_VOTING) {
            return handleVotingTask(prop);
        }
        return false;
    }

    // handleVotingTask handles only TASK_VOTING
    function handleVotingTask(ProposalDescription storage prop) internal returns (bool handled) {
        bool ready = statusVoting(prop.status) &&
        (prop.totalVotes >= prop.requiredVotes || block.timestamp >= prop.deadlines.votingEndTime);
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

    function cancelVote(uint256 proposalId) public {
        _cancelVote(proposalId, msg.sender);
    }

    function totalVotes(uint256 propType) public view returns (uint256) {
        return governableContract.getTotalVotes(propType);
    }

    function proceedToVoting(uint256 proposalId) internal {
        ProposalDescription storage prop = proposals[proposalId];
        prop.deadlines.votingStartTime = block.timestamp;
        prop.deadlines.votingEndTime = block.timestamp + votingPeriod();
        prop.status = setStatusVoting(prop.status);
        emit StartedProposalVoting(proposalId);
    }

    function resolveProposal(uint256 proposalId, uint256 winnerOptionId) internal {
        ProposalDescription storage prop = proposals[proposalId];
        require(statusVoting(prop.status), "proposal is not at voting period");

        if (prop.propType == typeExecutable()) {
            address propAddr = prop.proposalContract;
            propAddr.delegatecall(abi.encodeWithSignature("execute(uint256)", winnerOptionId));
        }

        prop.status = setStatusAccepted(prop.status);
        prop.chosenOption = winnerOptionId;
    }

    function calculateVotingResult(uint256 proposalId) internal returns(bool, uint256) {
        ProposalDescription storage prop = proposals[proposalId];
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

    function increaseVotersPower(uint256 proposalId, address voterAddr, uint256 power) internal {
        votes[voterAddr][proposalId].power += power;
        // reducedVotersPower[voter][proposalId] -= power;
        Vote storage v = votes[msg.sender][proposalId];
        v.power += power;
        addChoicesToProp(proposalId, v.choices, power);
    }

    function _cancelVote(uint256 proposalId, address voteAddr) internal {
        Vote memory v = votes[voteAddr][proposalId];

        // prop.choices[v.choice] -= v.power;
        if (votes[voteAddr][proposalId].previousDelegation != address(0)) {
            increaseVotersPower(proposalId, voteAddr, v.power);
        }

        removeChoicesFromProp(proposalId, v.choices, v.power);
        delete votes[voteAddr][proposalId];
    }

    function makeVote(uint256 proposalId, uint256[] memory choices, uint256 power) internal {

        Vote storage v = votes[msg.sender][proposalId];
        v.choices = choices;
        v.power = power;
        addChoicesToProp(proposalId, choices, power);

        emit UserVoted(msg.sender, proposalId, choices, power);
    }

    function addChoicesToProp(uint256 proposalId, uint256[] memory choices, uint256 power) internal {
        ProposalDescription storage prop = proposals[proposalId];

        require(choices.length == prop.optionIDs.length, "incorrect choices");

        prop.totalVotes += power;

        for (uint256 i = 0; i < prop.optionIDs.length; i++) {
            uint256 optionID = prop.optionIDs[i];
            prop.options[optionID].addVote(choices[i], power);
        }
    }

    function removeChoicesFromProp(uint256 proposalId, uint256[] memory choices, uint256 power) internal {
        ProposalDescription storage prop = proposals[proposalId];

        require(choices.length == prop.optionIDs.length, "incorrect choices");

        prop.totalVotes -= power;

        for (uint256 i = 0; i < prop.optionIDs.length; i++) {
            uint256 optionID = prop.optionIDs[i];
            prop.options[optionID].removeVote(choices[i], power);
        }
    }

    function recountVote(uint256 proposalId, address voterAddr) internal {
        Vote memory v = votes[voterAddr][proposalId];
        ProposalDescription storage prop = proposals[proposalId];
        _cancelVote(proposalId, voterAddr);

        (uint256 ownVotingPower, uint256 delegatedMeVotingPower, uint256 delegatedVotingPower) = accountVotingPower(voterAddr, prop.id);
        uint256 power;
        if (ownVotingPower > 0) {
            power = ownVotingPower + delegatedMeVotingPower - reducedVotersPower[voterAddr][proposalId];
        }
        if (delegatedVotingPower > 0) {
            power = delegatedVotingPower + delegatedMeVotingPower - reducedVotersPower[voterAddr][proposalId];
        }

        makeVote(proposalId, v.choices, power);
    }

    function reduceVotersPower(uint256 proposalId, address voter, uint256 power) internal {
        votes[voter][proposalId].power -= power;
        reducedVotersPower[voter][proposalId] += power;
        emit VotersPowerReduced(voter);
    }

    function accountVotingPower(address acc, uint256 proposalId) public view returns (uint256, uint256, uint256) {
        ProposalDescription memory prop = proposals[proposalId];
        return governableContract.getVotingPower(acc, prop.propType);
    }

    function votingDeadlines(uint256 proposalId) internal {
        ProposalDescription storage prop = proposals[proposalId];
        prop.deadlines.votingStartTime = block.timestamp;
        prop.deadlines.votingEndTime = block.timestamp + votingPeriod();
    }

    function addTasks(uint256 proposalId) internal {
        tasks.push(Task(true, proposalId, TASK_VOTING));
    }

    function burn(uint256 amount) internal {
        address(0).send(amount);
    }
}
