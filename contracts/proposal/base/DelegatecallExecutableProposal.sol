// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {BaseProposal} from "./BaseProposal.sol";
import {Proposal} from "../../governance/Proposal.sol";

/// @notice extended BaseProposal for any proposals with delegate call
contract DelegatecallExecutableProposal is BaseProposal {
    function executable() public override virtual view returns (Proposal.ExecType) {
        return Proposal.ExecType.DELEGATECALL;
    }

    function pType() public override virtual view returns (uint256) {
        return uint256(StdProposalTypes.UNKNOWN_DELEGATECALL_EXECUTABLE);
    }

    function executeDelegateCall(address, uint256) external override virtual{
        revert MustBeOverwritten();
    }
}
