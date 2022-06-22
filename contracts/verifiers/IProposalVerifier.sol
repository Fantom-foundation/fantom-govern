pragma solidity ^0.5.0;

import "../governance/Proposal.sol";

/**
 * @dev A verifier can verify a proposal's inputs such as proposal parameters and proposal contract.
 */
interface IProposalVerifier {
    // Verifies proposal parameters with respect to the stored template of same type
    function verifyProposalParams(uint256 pType, Proposal.ExecType executable, uint256 minVotes, uint256 minAgreement, uint256[] calldata opinionScales, uint256 start, uint256 minEnd, uint256 maxEnd) external view returns (bool);

    // Verifies proposal contract of the specified type and address
    function verifyProposalContract(uint256 pType, address propAddr) external view returns (bool);
}
