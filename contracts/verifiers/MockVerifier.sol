pragma solidity ^0.5.0;

import {IProposalVerifier} from "./IProposalVerifier.sol";
import "../governance/Proposal.sol";

// MockVerifier serves as a mock for testing governance. It always return true for any verification
contract MockVerifier is IProposalVerifier {
    function verifyProposalParams(uint256 pType, Proposal.ExecType executable, uint256 minVotes, uint256 minAgreement, uint256[] calldata opinionScales, uint256 start, uint256 minEnd, uint256 maxEnd) external view returns (bool) {
        return true;
    }
    function verifyProposalContract(uint256 pType, address propAddr) external view returns (bool) {
        return true;
    }
}
