// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {BaseProposal} from "./BaseProposal.sol";
import {Proposal} from "../../governance/Proposal.sol";

/// @notice extended BaseProposal for any proposals that can be executed
contract CallExecutableProposal is BaseProposal {
    // Returns execution type
    function executable() public override virtual view returns (Proposal.ExecType) {
        return Proposal.ExecType.CALL;
    }

    function pType() public override virtual view returns (uint256) {
        return uint256(StdProposalTypes.UNKNOWN_CALL_EXECUTABLE);
    }

    function executeCall(uint256) external override virtual {
        require(false, "must be overridden");
    }
}
