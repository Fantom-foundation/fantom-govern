pragma solidity ^0.5.0;

contract FakeVoteRecounter {
    address public expectVoterAddr;
    address public expectDelegatedTo;

    bool public failed;

    uint256[] public recounted;

    uint256[] public outdatedProposals;

    function getRecounted() external view returns(uint256[] memory) {
        return recounted;
    }

    function recountVote(address voterAddr, address delegatedTo, uint256 proposalID) external {
        for (uint256 i = 0; i < outdatedProposals.length; i++) {
            if (proposalID == outdatedProposals[i]) {
                revert();
            }
        }
        if (voterAddr != expectVoterAddr || delegatedTo != expectDelegatedTo) {
            failed = true;
        }
        recounted.push(proposalID);
    }

    function reset(address voterAddr, address delegatedTo) external {
        expectVoterAddr = voterAddr;
        expectDelegatedTo = delegatedTo;
        recounted.length = 0;
    }

    function setOutdatedProposals(uint256[] calldata proposalIDs) external {
        outdatedProposals = proposalIDs;
    }

    function proposalState(uint256 proposalID) external view returns (uint256 winnerOptionID, uint256 votes, uint256 status) {
        for (uint256 i = 0; i < outdatedProposals.length; i++) {
            if (proposalID == outdatedProposals[i]) {
                return (0, 0, 1);
            }
        }
        return (0, 0, 0);
    }
}
