// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../governance/Governance.sol";
import "./ScopedVerifier.sol";

/// @dev OwnableVerifier is a verifier that only allows the owner to create proposals
contract OwnableVerifier is ScopedVerifier, Ownable {
    constructor(address govAddress) public Ownable(msg.sender) {
        gov = Governance(govAddress);
    }

    Governance internal gov;

    function createProposal(address propAddr) payable external onlyOwner {
        unlockedFor = propAddr;
        gov.createProposal{value: msg.value}(propAddr);
        unlockedFor = address(0);
    }
}
