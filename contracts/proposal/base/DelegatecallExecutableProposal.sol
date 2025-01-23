// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./BaseProposal.sol";
import "../../governance/Proposal.sol";

/// @dev A base for any proposal that can be executed with delegatecall
contract DelegatecallExecutableProposal is BaseProposal {
    function executable() public override virtual view returns (Proposal.ExecType) {
        return Proposal.ExecType.DELEGATECALL;
    }

    function pType() public override virtual view returns (uint256) {
        return uint256(StdProposalTypes.UNKNOWN_DELEGATECALL_EXECUTABLE);
    }

    function execute_delegatecall(address, uint256) external override virtual{
        require(false, "must be overridden");
    }
}
