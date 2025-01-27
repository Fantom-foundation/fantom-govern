// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Governance} from "../governance/Governance.sol";
import {ScopedVerifier} from "./ScopedVerifier.sol";

/// @dev OwnableVerifier is a verifier that only allows the owner to create proposals
contract OwnableVerifier is ScopedVerifier, Ownable {
    constructor(address govAddress) Ownable(msg.sender) {
        gov = Governance(govAddress);
    }

    Governance internal gov;

    /// @notice create a new proposal
    /// @param propAddr The address of the proposal
    function createProposal(address propAddr) payable external onlyOwner {
        unlockedFor = propAddr;
        gov.createProposal{value: msg.value}(propAddr);
        unlockedFor = address(0);
    }
}
