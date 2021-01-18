pragma solidity ^0.5.0;

import "../ownership/Ownable.sol";
import "../governance/Governance.sol";
import "./ScopedVerifier.sol";


contract OwnableVerifier is ScopedVerifier, Ownable {
    constructor(address govAddress) public {
        Ownable.initialize(msg.sender);
        gov = Governance(govAddress);
    }

    Governance internal gov;

    function createProposal(address propAddr) payable external onlyOwner {
        unlockedFor = propAddr;
        gov.createProposal.value(msg.value)(propAddr);
        unlockedFor = address(0);
    }
}
