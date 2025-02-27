// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IProposalVerifier} from "./IProposalVerifier.sol";
import {Proposal} from "../governance/Proposal.sol";

contract ScopedVerifier is IProposalVerifier {
    address internal unlockedFor;

    error AppropriateFactoryNotUsed();

    // verifyProposalParams checks proposal parameters
    function verifyProposalParams(uint256, Proposal.ExecType, uint256, uint256, uint256[] calldata, uint256, uint256, uint256) external pure {}

    // verifyProposalContract verifies proposal creator
    function verifyProposalContract(uint256, address propAddr) external view {
        if (propAddr != unlockedFor) {
            revert AppropriateFactoryNotUsed();
        }
    }
}
