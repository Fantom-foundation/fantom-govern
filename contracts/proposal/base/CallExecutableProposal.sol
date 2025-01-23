// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./BaseProposal.sol";
import "../../governance/Proposal.sol";

/// @dev A base for any proposal that can be executed
contract CallExecutableProposal is BaseProposal {
    // Returns execution type
    function executable() public override virtual view returns (Proposal.ExecType) {
        return Proposal.ExecType.CALL;
    }

    function pType() public override virtual view returns (uint256) {
        return uint256(StdProposalTypes.UNKNOWN_CALL_EXECUTABLE);
    }

    function execute_call(uint256) external override virtual {
        require(false, "must be overridden");
    }
}
