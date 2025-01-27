// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../ownership/Ownable.sol";
import "../governance/Governance.sol";
import "./ScopedVerifier.sol";

/// @dev OwnableVerifier is a verifier that only allows the owner to create proposals
contract OwnableVerifier is ScopedVerifier, Ownable {
    constructor(address govAddress) {
        Ownable.initialize(msg.sender);
        _gov = Governance(govAddress);
    }

    Governance internal _gov;

    /// @notice create a new proposal
    /// @param propAddr The address of the proposal
    function createProposal(address propAddr) payable external onlyOwner {
        unlockedFor = propAddr;
        _gov.createProposal{value: msg.value}(propAddr);
        unlockedFor = address(0);
    }
}
