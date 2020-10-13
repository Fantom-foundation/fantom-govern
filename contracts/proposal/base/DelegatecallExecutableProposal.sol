pragma solidity ^0.5.0;

import "./BaseProposal.sol";
import "../../governance/Proposal.sol";

contract DelegatecallExecutableProposal is BaseProposal {
    // Returns execution type
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
