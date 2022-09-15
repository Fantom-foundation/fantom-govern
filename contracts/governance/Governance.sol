pragma solidity ^0.5.0;

import "../common/ReentrancyGuard.sol";
import "../common/SafeMath.sol";
import "../model/Governable.sol";
import "../proposal/base/IProposal.sol";
import "../verifiers/IProposalVerifier.sol";
import "../proposal/SoftwareUpgradeProposal.sol";
import "./Proposal.sol";
import "./Constants.sol";
import "./GovernanceSettings.sol";
import "./LRC.sol";
import "../version/Version.sol";

contract Governance is Initializable, ReentrancyGuard, GovernanceSettings, Version {
    using SafeMath for uint256;
    using LRC for LRC.Option;

    struct Vote {
        uint256 weight;
        uint256[] choices;
    }

    struct ProposalState {
        Proposal.Parameters params;

        // voting state
        mapping(uint256 => LRC.Option) options;
        uint256 winnerOptionID;
        uint256 votes; // total weight of votes

        uint256 status;
    }

    struct Task {
        bool active;
        uint256 assignment;
        uint256 proposalID;
    }

    Governable governableContract;
    IProposalVerifier proposalVerifier;
    uint256 public lastProposalID;
    uint256 public activeProposals;
    Task[] tasks;

    mapping(uint256 => ProposalState) proposals;
    mapping(address => mapping(uint256 => uint256)) public overriddenWeight; // voter address, proposalID -> weight
    mapping(address => mapping(address => mapping(uint256 => Vote))) _votes; // voter, delegationReceiver, proposalID -> Vote

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

    function initialize(address _governableContract, address _proposalVerifier) public initializer {
        ReentrancyGuard.initialize();
        governableContract = Governable(_governableContract);
        proposalVerifier = IProposalVerifier(_proposalVerifier);
    }

    function proposalParams(uint256 proposalID) public view returns (uint256 pType, Proposal.ExecType executable, uint256 minVotes, uint256 minAgreement, uint256[] memory opinionScales, bytes32[] memory options, address proposalContract, uint256 votingStartTime, uint256 votingMinEndTime, uint256 votingMaxEndTime) {
        Proposal.Parameters memory p = proposals[proposalID].params;
        return (p.pType, p.executable, p.minVotes, p.minAgreement, p.opinionScales, p.options, p.proposalContract, p.deadlines.votingStartTime, p.deadlines.votingMinEndTime, p.deadlines.votingMaxEndTime);
    }

    function proposalOptionState(uint256 proposalID, uint256 optionID) public view returns (uint256 votes, uint256 agreementRatio, uint256 agreement) {
        ProposalState storage prop = proposals[proposalID];
        LRC.Option storage opt = prop.options[optionID];
        return (opt.votes, LRC.agreementRatio(opt), opt.agreement);
    }

    function proposalState(uint256 proposalID) public view returns (uint256 winnerOptionID, uint256 votes, uint256 status) {
        ProposalState memory p = proposals[proposalID];
        return (p.winnerOptionID, p.votes, p.status);
    }

    function getVote(address from, address delegatedTo, uint256 proposalID) public view returns (uint256 weight, uint256[] memory choices) {
        Vote memory v = _votes[from][delegatedTo][proposalID];
        return (v.weight, v.choices);
    }

    function tasksCount() public view returns (uint256) {
        return (tasks.length);
    }

    function getTask(uint256 i) public view returns (bool active, uint256 assignment, uint256 proposalID) {
        Task memory t = tasks[i];
        return (t.active, t.assignment, t.proposalID);
    }

    function vote(address delegatedTo, uint256 proposalID, uint256[] calldata choices) nonReentrant external {
        if (delegatedTo == address(0)) {
            delegatedTo = msg.sender;
        }

        ProposalState storage prop = proposals[proposalID];

        require(prop.params.proposalContract != address(0), "proposal with a given ID doesnt exist");
        require(isInitialStatus(prop.status), "proposal isn't active");
        require(block.timestamp >= prop.params.deadlines.votingStartTime, "proposal voting hasn't begun");
        require(_votes[msg.sender][delegatedTo][proposalID].weight == 0, "vote already exists");
        require(choices.length == prop.params.options.length, "wrong number of choices");

        uint256 weight = _processNewVote(proposalID, msg.sender, delegatedTo, choices);
        require(weight != 0, "zero weight");
    }

    function createProposal(address proposalContract) nonReentrant external payable {
        require(msg.value == proposalFee(), "paid proposal fee is wrong");

        lastProposalID++;
        _createProposal(lastProposalID, proposalContract);
        addTasks(lastProposalID);

        // burn a non-reward part of the proposal fee
        burn(proposalBurntFee());

        emit ProposalCreated(lastProposalID);
        activeProposals++;
    }

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
        require(options.length != 0, "proposal options are empty - nothing to vote for");
        require(options.length <= maxOptions(), "too many options");
        bool ok;
        ok = proposalVerifier.verifyProposalParams(pType, executable, minVotes, minAgreement, opinionScales, votingStartTime, votingMinEndTime, votingMaxEndTime);
        require(ok, "proposal parameters failed verification");
        ok = proposalVerifier.verifyProposalContract(pType, proposalContract);
        require(ok, "proposal contract failed verification");
        // save the parameters
        ProposalState storage prop = proposals[proposalID];
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

    // cancelProposal cancels the proposal if no one managed to vote yet
    // must be sent from the proposal contract
    function cancelProposal(uint256 proposalID) nonReentrant external {
        ProposalState storage prop = proposals[proposalID];
        require(prop.params.proposalContract != address(0), "proposal with a given ID doesnt exist");
        require(isInitialStatus(prop.status), "proposal isn't active");
        require(prop.votes == 0, "voting has already begun");
        require(msg.sender == prop.params.proposalContract, "must be sent from the proposal contract");

        prop.status = statusCanceled();
        emit ProposalCanceled(proposalID);
        activeProposals--;
    }

    // handleTasks triggers proposal deadlines processing for a specified range of tasks
    function handleTasks(uint256 startIdx, uint256 quantity) nonReentrant external {
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
        msg.sender.transfer(handled.mul(taskHandlingReward()));
    }

    // tasksCleanup erases inactive (handled) tasks backwards until an active task is met
    function tasksCleanup(uint256 quantity) nonReentrant external {
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
        // reward the sender
        msg.sender.transfer(erased.mul(taskErasingReward()));
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
            // deactivate all tasks for non-active proposals
            return true;
        }
        if (assignment == TASK_VOTING) {
            return handleVotingTask(proposalID, prop);
        }
        return false;
    }

    // handleVotingTask handles only TASK_VOTING
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
                prop.status = statusResolved();
                emit ProposalResolved(proposalID);
                activeProposals--;
            } else {
                prop.status = statusExecutionExpired();
                emit ProposalExecutionExpired(proposalID);
            }
        } else {
            prop.status = statusFailed();
            emit ProposalRejected(proposalID);
            activeProposals--;
        }
        return true;
    }

    function executeProposal(ProposalState storage prop, uint256 winnerOptionID) internal returns (bool, bool) {
        bool executable = prop.params.executable == Proposal.ExecType.CALL || prop.params.executable == Proposal.ExecType.DELEGATECALL;
        if (!executable) {
            return (true, false);
        }
        prop.winnerOptionID = winnerOptionID;

        bool executionExpired = block.timestamp > prop.params.deadlines.votingMaxEndTime + maxExecutionPeriod();
        if (executionExpired) {
            // protection against proposals which revert or consume too much gas
            return (true, true);
        }
        address propAddr = prop.params.proposalContract;
        bool success;
        bytes memory result;
        if (prop.params.executable == Proposal.ExecType.CALL) {
            (success, result) = propAddr.call(abi.encodeWithSignature("execute_call(uint256)", winnerOptionID));
        } else {
            (success, result) = propAddr.delegatecall(abi.encodeWithSignature("execute_delegatecall(address,uint256)", propAddr, winnerOptionID));
        }
        result;
        return (success, false);
    }

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

    // calculateVotingTally calculates the voting tally and returns {is finished, won option ID, total weight of votes}
    function calculateVotingTally(uint256 proposalID) external view returns (bool proposalResolved, uint256 winnerID, uint256 votes) {
        ProposalState storage prop = proposals[proposalID];
        (proposalResolved, winnerID) = _calculateVotingTally(prop);
        return (proposalResolved, winnerID, prop.votes);
    }

    function cancelVote(address delegatedTo, uint256 proposalID) nonReentrant external {
        if (delegatedTo == address(0)) {
            delegatedTo = msg.sender;
        }
        Vote memory v = _votes[msg.sender][delegatedTo][proposalID];
        require(v.weight != 0, "doesn't exist");
        require(isInitialStatus(proposals[proposalID].status), "proposal isn't active");
        _cancelVote(msg.sender, delegatedTo, proposalID);
    }

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

        emit VoteCanceled(voter, delegatedTo, proposalID);
    }

    function makeVote(uint256 proposalID, address voter, address delegatedTo, uint256[] memory choices, uint256 weight) internal {
        _votes[voter][delegatedTo][proposalID] = Vote(weight, choices);
        addChoicesToProp(proposalID, choices, weight);

        emit Voted(voter, delegatedTo, proposalID, choices, weight);
    }

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

    function recountVote(address voterAddr, address delegatedTo, uint256 proposalID) nonReentrant external {
        Vote storage v = _votes[voterAddr][delegatedTo][proposalID];
        Vote storage vSuper = _votes[delegatedTo][delegatedTo][proposalID];
        require(v.choices.length > 0, "doesn't exist");
        require(isInitialStatus(proposals[proposalID].status), "proposal isn't active");
        uint256 beforeSelf = v.weight;
        uint256 beforeSuper = vSuper.weight;
        _recountVote(voterAddr, delegatedTo, proposalID);
        uint256 afterSelf = v.weight;
        uint256 afterSuper = vSuper.weight;
        // check that some weight has changed due to recounting
        require(beforeSelf != afterSelf || beforeSuper != afterSuper, "nothing changed");
    }

    function _recountVote(address voterAddr, address delegatedTo, uint256 proposalID) internal returns (uint256) {
        uint256[] memory origChoices = _votes[voterAddr][delegatedTo][proposalID].choices;
        // cancel previous vote
        _cancelVote(voterAddr, delegatedTo, proposalID);
        // re-make vote
        return _processNewVote(proposalID, voterAddr, delegatedTo, origChoices);
    }

    function overrideDelegationWeight(address delegatedTo, uint256 proposalID, uint256 weight) internal {
        uint256 overridden = overriddenWeight[delegatedTo][proposalID];
        overridden = overridden.add(weight);
        overriddenWeight[delegatedTo][proposalID] = overridden;
        Vote storage v = _votes[delegatedTo][delegatedTo][proposalID];
        if (v.choices.length > 0) {
            v.weight = v.weight.sub(weight);
            removeChoicesFromProp(proposalID, v.choices, weight);
        }
        emit VoteWeightOverridden(delegatedTo, weight);
    }

    function unOverrideDelegationWeight(address delegatedTo, uint256 proposalID, uint256 weight) internal {
        uint256 overridden = overriddenWeight[delegatedTo][proposalID];
        overridden = overridden.sub(weight);
        overriddenWeight[delegatedTo][proposalID] = overridden;
        Vote storage v = _votes[delegatedTo][delegatedTo][proposalID];
        if (v.choices.length > 0) {
            v.weight = v.weight.add(weight);
            addChoicesToProp(proposalID, v.choices, weight);
        }
        emit VoteWeightUnOverridden(delegatedTo, weight);
    }

    function addChoicesToProp(uint256 proposalID, uint256[] memory choices, uint256 weight) internal {
        ProposalState storage prop = proposals[proposalID];

        prop.votes = prop.votes.add(weight);

        for (uint256 i = 0; i < prop.params.options.length; i++) {
            prop.options[i].addVote(choices[i], weight, prop.params.opinionScales);
        }
    }

    function removeChoicesFromProp(uint256 proposalID, uint256[] memory choices, uint256 weight) internal {
        ProposalState storage prop = proposals[proposalID];

        prop.votes = prop.votes.sub(weight);

        for (uint256 i = 0; i < prop.params.options.length; i++) {
            prop.options[i].removeVote(choices[i], weight, prop.params.opinionScales);
        }
    }

    function addTasks(uint256 proposalID) internal {
        tasks.push(Task(true, TASK_VOTING, proposalID));
    }

    function burn(uint256 amount) internal {
        address(0).transfer(amount);
    }
}
