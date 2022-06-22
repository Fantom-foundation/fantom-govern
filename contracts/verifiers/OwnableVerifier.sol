pragma solidity ^0.5.0;

import "../ownership/Ownable.sol";
import "./IProposalVerifier.sol";
import "../governance/Governance.sol";


contract OwnableVerifier is IProposalVerifier, Ownable {
    constructor(address govAddress) public {
        Ownable.initialize(msg.sender);
        gov = Governance(govAddress);
    }

    Governance gov;
    address unlockedFor;

    function createProposal(address propAddr) payable external onlyOwner {
        unlockedFor = propAddr;
        gov.createProposal.value(msg.value)(propAddr);
        unlockedFor = address(0);
    }

    // verifyProposalParams checks proposal parameters
    function verifyProposalParams(uint256, Proposal.ExecType, uint256, uint256, uint256[] calldata, uint256, uint256, uint256) external view returns (bool) {
        return true;
    }

    // verifyProposalContract verifies proposal creator
    function verifyProposalContract(uint256, address propAddr) external view returns (bool) {
        return propAddr == unlockedFor;
    }
}
