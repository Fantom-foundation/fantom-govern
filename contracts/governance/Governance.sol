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

    struct Voter {
        uint256 power;
        uint256[] choises;
        address previousDelegation;
    }

    struct ProposalTimeline {
        uint256 depositingStartTime;
        uint256 depositingEndTime;
        uint256 votingStartTime;
        uint256 votingEndTime;
    }

    struct ProposalDescription {
        ProposalTimeline deadlines;
        string description;
        uint256 id;
        uint256 requiredDeposit;
        uint256 requiredVotes;
        uint256 deposit;
        uint256 status;
        mapping(uint256 => LRC.LrcOption) options;
        uint256[] optionIDs;
        uint256 lastOptionID;
        uint256 chosenOption;
        uint256 totalVotes;
        uint8 propType;
        address proposalContract;
        // mapping(address => uint256[]);
    }

    Governable governableContract;
    ImplementationValidator implementationValidator;
    IProposalFactory proposalFactory;
    uint256 public lastProposalId;
    uint256[] public deadlines;
    uint256[] public inactiveProposalIds;
    bytes4 abstractProposalInterfaceId;

    mapping(uint256 => ProposalDescription) proposals;
    mapping(uint256 => ProposalTimeline) proposalDeadlines; // proposal ID to Deadline
    mapping(address => mapping(uint256 => uint256)) public reducedVotersPower; // sender address to proposal id to power
    mapping(address => mapping(uint256 => uint256)) public depositors; // sender address to proposal id to deposit
    mapping(address => mapping(uint256 => Voter)) public voters;
    mapping(uint256 => uint256[]) public proposalsAtDeadline; // deadline to proposal ids
//    mapping(uint256 => uint256) public idxToDeadlines; // index to deadline

    event ProposalIsCreated(uint256 proposalId);
    event ProposalIsResolved(uint256 proposalId);
    event ProposalIsRejected(uint256 proposalId);
    event ProposalDepositIncreased(address depositor, uint256 proposalId, uint256 value, uint256 newTotalDeposit);
    event StartedProposalVoting(uint256 proposalId);
    event DeadlinesResolved(uint256 startIdx, uint256 quantity);
    event ResolvedProposal(uint256 proposalId);
    event ImplementedProposal(uint256 proposalId);
    event DeadlineRemoved(uint256 deadline);
    event DeadlineAdded(uint256 deadline);
    event GovernableContractSet(address addr);
    event SoftwareVersionAdded(string version, address addr);
    event VotersPowerReduced(address voter);
    event UserVoted(address voter, uint256 proposalId, uint256[] choises, uint256 power);

    constructor (address _governableContract, address _proposalFactory) public {
        governableContract = Governable(_governableContract);
        proposalFactory = IProposalFactory(_proposalFactory);
    }

    function getProposalDepDeadline(uint256 proposalId) public view returns (uint256) {
        ProposalDescription storage prop = proposals[proposalId];
        return (prop.deadlines.depositingEndTime);
    }

    function getProposalStatus(uint256 proposalId) public view returns (uint256) {
        ProposalDescription storage prop = proposals[proposalId];
        return (prop.status);
    }

    function getDeadlinesCount() public view returns (uint256) {
        return (deadlines.length);
    }

    function getProposalDescription(uint256 proposalId) public view 
    returns (
        string memory description,
        uint256 requiredVotes,
        uint256 deposit,
        uint256 status,
        uint256 chosenOption,
        uint256 totalVotes,
        address proposalContract) {
        ProposalDescription storage prop = proposals[proposalId];

        return (
            prop.description,
            prop.requiredVotes,
            prop.deposit,
            prop.status,
            prop.chosenOption,
            prop.totalVotes,
            prop.proposalContract
        );
    }

    function vote(uint256 proposalId, uint256[] memory choises) public {
        ProposalDescription storage prop = proposals[proposalId];

        require(prop.id == proposalId, "proposal with a given id doesnt exist");
        require(statusVoting(prop.status), "proposal is not at voting period");
        require(voters[msg.sender][proposalId].power == 0, "this account has already voted. try to cancel a vote if you want to revote");
        require(prop.deposit != 0, "proposal didnt enter depositing period");
        require(prop.deposit >= prop.requiredDeposit, "proposal is not at voting period");
        require(choises.length == prop.optionIDs.length, "incorrect choises");

        (uint256 ownVotingPower, uint256 delegationVotingPower, uint256 delegatedVotingPower) = accountVotingPower(msg.sender, prop.id);

        if (ownVotingPower != 0) {
            uint256 power = ownVotingPower + delegationVotingPower - reducedVotersPower[msg.sender][proposalId];
            makeVote(proposalId, choises, power);
        }

        if (delegatedVotingPower != 0) {
            address delegatedTo = governableContract.delegatedVotesTo(msg.sender);
            recountVoter(proposalId, delegatedTo);
            reduceVotersPower(proposalId, delegatedTo, delegatedVotingPower);
            makeVote(proposalId, choises, delegatedVotingPower);
            voters[msg.sender][proposalId].previousDelegation = delegatedTo;
        }
    }

    function increaseProposalDeposit(uint256 proposalId) public payable {
        ProposalDescription storage prop = proposals[proposalId];

        require(prop.id == proposalId, "proposal with a given id doesnt exist");
        require(statusDepositing(prop.status), "proposal is not depositing");
        require(msg.value > 0, "msg.value is zero");
        require(block.timestamp < prop.deadlines.depositingEndTime, "cannot deposit to an overdue proposal");

        prop.deposit += msg.value;
        depositors[msg.sender][prop.id] += msg.value;
        emit ProposalDepositIncreased(msg.sender, proposalId, msg.value, prop.deposit);
    }

    function createProposal(address proposalContract, uint256 requiredDeposit) public payable {
        validateProposalContract(proposalContract);
        require(msg.value >= minimumStartingDeposit(), "starting deposit is not enough");
        require(requiredDeposit >= minimumDeposit(), "required deposit for a proposal is too small");
        require (proposalFactory.canVoteForProposal(proposalContract), "cannot vote for a given proposal");

        AbstractProposal proposal = AbstractProposal(proposalContract);
        bytes32[] memory options = proposal.getOptions();
        require(options.length != 0, "proposal options is empty - nothing to vote for");


        lastProposalId++;
        ProposalDescription storage prop = proposals[lastProposalId];
        prop.id = lastProposalId;
        prop.requiredDeposit = requiredDeposit;
        prop.status = setStatusDepositing(0);
        prop.requiredVotes = minimumVotesRequired(totalVotes(prop.propType));
        for (uint256 i = 0; i < options.length; i++) {
            prop.lastOptionID++;
            LRC.LrcOption storage option = prop.options[prop.lastOptionID];
            option.description = options[i];
            // option.description = bytes32ToString(choises[i]);
            prop.optionIDs.push(prop.lastOptionID);
        }
        prop.deposit = msg.value;
        prop.proposalContract = proposalContract;
        depositingDeadlines(lastProposalId);
        votingDeadlines(lastProposalId);
        saveDeadlines(lastProposalId);
        proposalFactory.setProposalIsConsidered(proposalContract);

        emit ProposalIsCreated(lastProposalId);
    }

    function validateProposalContract(address proposalContract) public {
        AbstractProposal proposal = AbstractProposal(proposalContract);
        require(proposal.supportsInterface(abstractProposalInterfaceId), "address does not implement proposal interface");
    }

    function handleDeadlines(uint256 startIdx, uint256 quantity) public {
        require(startIdx < deadlines.length, "incorrect indexes passed");

        if (quantity > deadlines.length - startIdx) {
            quantity = deadlines.length - startIdx;
        }

        for (uint256 i = 0; i < quantity; i++) {
            handleDeadline(deadlines[startIdx+i]);
        }

        removeDeadlines(startIdx, quantity);

        emit DeadlinesResolved(startIdx, quantity);
    }

    function handleDeadline(uint256 deadline) public {
        uint256[] memory proposalIds = proposalsAtDeadline[deadline];

        for (uint256 i = 0; i < proposalIds.length; i++) {
            uint256 proposalId = proposalIds[i];
            handleProposalDeadline(proposalId);
        }

        emit DeadlineRemoved(deadline);
    }

    function handleProposalDeadline(uint256 proposalId) public {
        ProposalDescription storage prop = proposals[proposalId];
        if (statusDepositing(prop.status)) {
            if (prop.deposit >= prop.requiredDeposit) {
                proceedToVoting(prop.id);
                return;
            }
        }

        if (statusVoting(prop.status)) {
            (bool proposalAccepted, uint256 winnerId) = calculateVotingResult(proposalId);
            emit ProposalIsRejected(proposalId);
            if (proposalAccepted) {
                resolveProposal(prop.id, winnerId);
                return;
            }
        }

        failProposal(prop.id);
    }

    function removeDeadlines(uint256 startIdx, uint256 endIdx)  internal {

        for (uint i = endIdx; i > startIdx; i--) {
            delete proposalsAtDeadline[deadlines[i]];
            deadlines.length--;
        }

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
        require(prop.totalVotes >= prop.requiredVotes, "proposal has not enough votes to resolve");
        require(prop.deadlines.votingEndTime >= block.timestamp, "proposal voting deadline is not passed");

        if (prop.propType == typeExecutable()) {
            address propAddr = prop.proposalContract;
            propAddr.delegatecall(abi.encodeWithSignature("execute(uint256)", winnerOptionId));
        }

        prop.status = setStatusAccepted(prop.status);
        prop.chosenOption = winnerOptionId;
        inactiveProposalIds.push(proposalId);
        emit ResolvedProposal(proposalId);
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
        voters[voterAddr][proposalId].power += power;
        // reducedVotersPower[voter][proposalId] -= power;
        Voter storage voter = voters[msg.sender][proposalId];
        voter.power += power;
        addChoisesToProp(proposalId, voter.choises, power);
    }

    function _cancelVote(uint256 proposalId, address voterAddr) internal {
        Voter memory voter = voters[voterAddr][proposalId];
        ProposalDescription storage prop = proposals[proposalId];

        // prop.choises[voter.choise] -= voter.power;
        if (voters[voterAddr][proposalId].previousDelegation != address(0)) {
            increaseVotersPower(proposalId, voterAddr, voter.power);
        }

        removeChoisesFromProp(proposalId, voter.choises, voter.power);
        delete voters[voterAddr][proposalId];
    }

    function makeVote(uint256 proposalId, uint256[] memory choises, uint256 power) internal {

        Voter storage voter = voters[msg.sender][proposalId];
        voter.choises = choises;
        voter.power = power;
        addChoisesToProp(proposalId, choises, power);

        emit UserVoted(msg.sender, proposalId, choises, power);
    }

    function addChoisesToProp(uint256 proposalId, uint256[] memory choises, uint256 power) internal {
        ProposalDescription storage prop = proposals[proposalId];

        require(choises.length == prop.optionIDs.length, "incorrect choises");

        prop.totalVotes += power;

        for (uint256 i = 0; i < prop.optionIDs.length; i++) {
            uint256 optionID = prop.optionIDs[i];
            prop.options[optionID].addVote(choises[i], power);
        }
    }

    function removeChoisesFromProp(uint256 proposalId, uint256[] memory choises, uint256 power) internal {
        ProposalDescription storage prop = proposals[proposalId];

        require(choises.length == prop.optionIDs.length, "incorrect choises");

        prop.totalVotes -= power;

        for (uint256 i = 0; i < prop.optionIDs.length; i++) {
            uint256 optionID = prop.optionIDs[i];
            prop.options[optionID].removeVote(choises[i], power);
        }
    }

    function recountVoter(uint256 proposalId, address voterAddr) internal {
        Voter memory voter = voters[voterAddr][proposalId];
        ProposalDescription storage prop = proposals[proposalId];
        _cancelVote(proposalId, voterAddr);

        (uint256 ownVotingPower, uint256 delegationVotingPower, uint256 delegatedVotingPower) = accountVotingPower(voterAddr, prop.id);
        uint256 power;
        if (ownVotingPower > 0) {
            power = ownVotingPower + delegationVotingPower - reducedVotersPower[voterAddr][proposalId];
        }
        if (delegatedVotingPower > 0) {
            power = delegatedVotingPower + delegationVotingPower - reducedVotersPower[voterAddr][proposalId];
        }

        makeVote(proposalId, voter.choises, power);
    }

    function reduceVotersPower(uint256 proposalId, address voter, uint256 power) internal {
        // uint256[] choises = voters[voter][proposalId].choises;

        ProposalDescription storage prop = proposals[proposalId];
        voters[voter][proposalId].power -= power;
        reducedVotersPower[voter][proposalId] += power;
        emit VotersPowerReduced(voter);
    }

    function accountVotingPower(address acc, uint256 proposalId) public view returns (uint256, uint256, uint256) {
        ProposalDescription memory prop = proposals[proposalId];
        return governableContract.getVotingPower(acc, prop.propType);
    }

    function failProposal(uint256 proposalId) internal {
        ProposalDescription storage prop = proposals[proposalId];
        if (statusDepositing(prop.status)) {
            require(prop.deadlines.depositingEndTime < block.timestamp, "depositing period didnt end");
        }
        if (statusVoting(prop.status)) {
            require(prop.deadlines.votingEndTime < block.timestamp, "voting period didnt end");
        }

        prop.status = failStatus(prop.status);
        inactiveProposalIds.push(prop.id);
        emit ProposalIsRejected(proposalId);
    }

    function depositingDeadlines(uint256 proposalId) internal {
        ProposalDescription storage prop = proposals[proposalId];
        prop.deadlines.depositingStartTime = block.timestamp;
        prop.deadlines.depositingEndTime = block.timestamp + depositingPeriod();
    }

    function votingDeadlines(uint256 proposalId) internal {
        ProposalDescription storage prop = proposals[proposalId];
        prop.deadlines.votingStartTime = block.timestamp;
        prop.deadlines.votingEndTime = block.timestamp + votingPeriod();
    }

    function saveDeadlines(uint256 proposalId) internal {
        ProposalDescription storage prop = proposals[proposalId];

        proposalDeadlines[proposalId] = prop.deadlines;

        deadlines.push(prop.deadlines.votingEndTime);
        proposalsAtDeadline[prop.deadlines.votingEndTime].push(proposalId);

        deadlines.push(prop.deadlines.depositingEndTime);
        proposalsAtDeadline[prop.deadlines.depositingEndTime].push(proposalId);
    }
}
