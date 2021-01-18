pragma solidity ^0.5.0;

import "./IProposalVerifier.sol";
import "../governance/Governance.sol";

contract ScopedVerifier is IProposalVerifier {
    address internal unlockedFor;

    // verifyProposalParams checks proposal parameters
    function verifyProposalParams(uint256, Proposal.ExecType, uint256, uint256, uint256[] calldata, uint256, uint256, uint256) external view returns (bool) {
        return true;
    }

    // verifyProposalContract verifies proposal creator
    function verifyProposalContract(uint256, address propAddr) external view returns (bool) {
        return propAddr == unlockedFor;
    }
}
