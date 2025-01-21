pragma solidity ^0.5.0;

import "../ownership/Ownable.sol";

/// @dev Interface for the governance contract
interface GovernanceI {
    function recountVote(address voterAddr, address delegatedTo, uint256 proposalID) external;

    function proposalState(uint256 proposalID) external view returns (uint256 winnerOptionID, uint256 votes, uint256 status);
}

/// @dev A contract that keeps track of votes
contract VotesBookKeeper is Initializable, Ownable {
    address gov; // Address of the governance contract

    uint256 public maxProposalsPerVoter; // Maximum number of proposals a voter can vote on

    mapping(address => mapping(address => uint256[])) votesList; // voter => delegatedTo => []proposal IDs

    // voter => delegatedTo => proposal ID => {index in the list + 1}
    mapping(address => mapping(address => mapping(uint256 => uint256))) votesIndex;

    /// @dev Initialize the contract
    /// @param _owner The owner of the contract
    /// @param _gov The address of the governance contract
    /// @param _maxProposalsPerVoter The maximum number of proposals a voter can vote on
    function initialize(address _owner, address _gov, uint256 _maxProposalsPerVoter) public initializer {
        Ownable.initialize(_owner);
        gov = _gov;
        maxProposalsPerVoter = _maxProposalsPerVoter;
    }

    function getProposalIDs(address voter, address delegatedTo) public view returns (uint256[] memory) {
        return votesList[voter][delegatedTo];
    }

    /// @dev Get vote index plus 1 if vote exists. Returns 0 if vote doesn't exist
    /// @param voter The address of the voter
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param proposalID The ID of the proposal
    /// @return The index of the vote plus 1 if the vote exists, otherwise 0
    function getVoteIndex(address voter, address delegatedTo, uint256 proposalID) public view returns (uint256) {
        return votesIndex[voter][delegatedTo][proposalID];
    }

    /// @dev Recount votes for a voter
    /// @param voter The address of the voter
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    function recountVotes(address voter, address delegatedTo) public {
        uint256[] storage list = votesList[voter][delegatedTo];
        uint256 origLen = list.length;
        uint256 i = 0;
        for (uint256 iter = 0; iter < origLen; iter++) {
            (bool success,) = gov.call(abi.encodeWithSignature("recountVote(address,address,uint256)", voter, delegatedTo, list[i]));
            bool evicted = false;
            if (!success) {
                // unindex if proposal isn't active
                (,, uint256 status) = GovernanceI(gov).proposalState(list[i]);
                if (status != 0) {
                    eraseVote(voter, delegatedTo, list[i], i + 1);
                    evicted = true;
                }
            }
            if (!evicted) {
                i++;
            }
        }
    }

    /// @dev Add a vote to the list of votes
    /// Should be called when a new vote is created
    /// @param voter The address of the voter
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param proposalID The ID of the proposal
    function onVoted(address voter, address delegatedTo, uint256 proposalID) external {
        uint256 idx = votesIndex[voter][delegatedTo][proposalID];
        if (idx > 0) {
            return;
        }
        if (votesList[voter][delegatedTo].length >= maxProposalsPerVoter) {
            // erase votes for outdated proposals
            recountVotes(voter, delegatedTo);
        }
        votesList[voter][delegatedTo].push(proposalID);
        idx = votesList[voter][delegatedTo].length;
        require(idx <= maxProposalsPerVoter, "too many votes");
        votesIndex[voter][delegatedTo][proposalID] = idx;
    }

    /// @dev Remove a vote from the list of votes
    /// Should be called when a vote is canceled
    /// @param voter The address of the voter
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param proposalID The ID of the proposal
    function onVoteCanceled(address voter, address delegatedTo, uint256 proposalID) external {
        uint256 idx = votesIndex[voter][delegatedTo][proposalID];
        if (idx == 0) {
            return;
        }
        eraseVote(voter, delegatedTo, proposalID, idx);
    }

    /// @dev Remove a vote from the list of votes
    /// @param voter The address of the voter
    /// @param delegatedTo The address of the delegator which the sender has delegated their stake to.
    /// @param proposalID The ID of the proposal
    function eraseVote(address voter, address delegatedTo, uint256 proposalID, uint256 idx) internal {
        votesIndex[voter][delegatedTo][proposalID] = 0;
        uint256[] storage list = votesList[voter][delegatedTo];
        uint256 len = list.length;
        if (len == idx) {
            // last element
            list.length--;
        } else {
            uint256 last = list[len - 1];
            list[idx - 1] = last;
            list.length--;
            votesIndex[voter][delegatedTo][last] = idx;
        }
    }

    /// @dev Set the maximum number of proposals a voter can vote on
    /// @param v The new maximum number of proposals
    function setMaxProposalsPerVoter(uint256 v) onlyOwner external {
        maxProposalsPerVoter = v;
    }
}
