pragma solidity ^0.5.0;

import "./IProposal.sol";

/**
 * @dev A verifier can verify a proposal's inputs such as proposal parameters and proposal code.
 */ 
interface IProposalVerifier {
    // Verifies proposal parameters with respect to the stored template of same type
    function verifyProposalParams(IProposal.StdProposalTypes pType, bool exec, uint256 minVotes, uint256 start, uint256 minEnd, uint256 maxEnd) external view returns (bool);
    
    // Verifies proposal code of the specified type and address
    function verifyProposalCode(IProposal.StdProposalTypes pType, address propAddr) external view returns (bool);
}
