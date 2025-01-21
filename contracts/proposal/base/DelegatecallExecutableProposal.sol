pragma solidity ^0.5.0;

import "./BaseProposal.sol";
import "../../governance/Proposal.sol";

/// @dev A base for any proposal that can be executed with delegatecall
contract DelegatecallExecutableProposal is BaseProposal {
    function executable() public view returns (Proposal.ExecType) {
        return Proposal.ExecType.DELEGATECALL;
    }

    function pType() public view returns (uint256) {
        return uint256(StdProposalTypes.UNKNOWN_DELEGATECALL_EXECUTABLE);
    }

    function execute_delegatecall(address, uint256) external {
        require(false, "must be overridden");
    }
}
