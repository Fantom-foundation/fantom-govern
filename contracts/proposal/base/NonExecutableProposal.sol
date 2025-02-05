// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {BaseProposal} from "./BaseProposal.sol";
import {Proposal} from "../../governance/Proposal.sol";

/// @notice extended BaseProposal for any proposals that cannot be executed
contract NonExecutableProposal is BaseProposal {
    function pType() public override virtual view returns (uint256) {
        return uint256(StdProposalTypes.UNKNOWN_NON_EXECUTABLE);
    }

    // Returns execution type
    function executable() public override virtual view returns (Proposal.ExecType) {
        return Proposal.ExecType.NONE;
    }
}
