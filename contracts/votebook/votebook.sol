pragma solidity ^0.5.0;

import "../ownership/Ownable.sol";

interface GovernanceI {
    function recountVote(address voterAddr, address delegatedTo, uint256 proposalID) external;

    function proposalState(uint256 proposalID) external view returns (uint256 winnerOptionID, uint256 votes, uint256 status);
}

contract VotesBookKeeper is Initializable, Ownable {
    address gov;

    uint256 public maxProposalsPerVoter;

    // voter, delegatedTo -> []proposal IDs
    mapping(address => mapping(address => uint256[])) votesList;

    // voter, delegatedTo, proposal ID -> {index in the list + 1}
    mapping(address => mapping(address => mapping(uint256 => uint256))) votesIndex;

    function initialize(address _owner, address _gov, uint256 _maxProposalsPerVoter) public initializer {
        Ownable.initialize(_owner);
        gov = _gov;
        maxProposalsPerVoter = _maxProposalsPerVoter;
    }

    function getProposalIDs(address voter, address delegatedTo) public view returns (uint256[] memory) {
        return votesList[voter][delegatedTo];
    }

    // returns vote index plus 1 if vote exists. Returns 0 if vote doesn't exist
    function getVoteIndex(address voter, address delegatedTo, uint256 proposalID) public view returns (uint256) {
        return votesIndex[voter][delegatedTo][proposalID];
    }

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

    function onVoteCanceled(address voter, address delegatedTo, uint256 proposalID) external {
        uint256 idx = votesIndex[voter][delegatedTo][proposalID];
        if (idx == 0) {
            return;
        }
        eraseVote(voter, delegatedTo, proposalID, idx);
    }

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

    function setMaxProposalsPerVoter(uint256 v) onlyOwner external {
        maxProposalsPerVoter = v;
    }
}
