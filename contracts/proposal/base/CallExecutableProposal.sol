pragma solidity ^0.5.0;

import "./BaseProposal.sol";
import "../../governance/Proposal.sol";

/// @notice extended BaseProposal for any proposals that can be executed
contract CallExecutableProposal is BaseProposal {
    // Returns execution type
    function executable() public view returns (Proposal.ExecType) {
        return Proposal.ExecType.CALL;
    }

    function pType() public view returns (uint256) {
        return uint256(StdProposalTypes.UNKNOWN_CALL_EXECUTABLE);
    }

    function execute_call(uint256) external {
        require(false, "must be overridden");
    }
}
