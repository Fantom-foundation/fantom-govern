pragma solidity ^0.5.0;

import "../ownership/Ownable.sol";
import "../governance/Governance.sol";
import "./ScopedVerifier.sol";

/// @dev OwnableVerifier is a verifier that only allows the owner to create proposals
contract OwnableVerifier is ScopedVerifier, Ownable {
    constructor(address govAddress) public {
        Ownable.initialize(msg.sender);
        gov = Governance(govAddress);
    }

    Governance internal gov;

    /// @notice create a new proposal
    /// @param propAddr The address of the proposal
    function createProposal(address propAddr) payable external onlyOwner {
        unlockedFor = propAddr;
        gov.createProposal.value(msg.value)(propAddr);
        unlockedFor = address(0);
    }
}
