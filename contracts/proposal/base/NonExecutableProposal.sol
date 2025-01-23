// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./BaseProposal.sol";
import "../../governance/Proposal.sol";

/// @dev A base for any non-executable proposal
contract NonExecutableProposal is BaseProposal {
    function pType() public override virtual view returns (uint256) {
        return uint256(StdProposalTypes.UNKNOWN_NON_EXECUTABLE);
    }

    // Returns execution type
    function executable() public override virtual view returns (Proposal.ExecType) {
        return Proposal.ExecType.NONE;
    }
}
