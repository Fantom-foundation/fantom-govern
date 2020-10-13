pragma solidity ^0.5.0;

import "./BaseProposal.sol";
import "../../governance/Proposal.sol";

contract NonExecutableProposal is BaseProposal {
    function pType() public view returns (uint256) {
        return uint256(StdProposalTypes.UNKNOWN_NON_EXECUTABLE);
    }

    // Returns execution type
    function executable() public view returns (Proposal.ExecType) {
        return Proposal.ExecType.NONE;
    }
}
