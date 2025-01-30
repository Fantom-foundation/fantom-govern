pragma solidity ^0.5.0;

import "../governance/Proposal.sol";


/// @notice A verifier can verify a proposal's inputs such as proposal parameters and proposal contract.
interface IProposalVerifier {
    /// @notice Verify proposal parameters
    /// @dev Each proposal type has a template to which the data in proposal must correspond
    /// @param pType The type of the template
    /// @param executable The type of execution
    /// @param minVotes The minimum number of votes required
    /// @param minAgreement The minimum agreement required
    /// @param opinionScales The opinion scales
    /// @param start The start time
    /// @param minEnd The minimum end time
    /// @param maxEnd The maximum end time
    /// @return true if the proposal parameters are valid
    function verifyProposalParams(
        uint256 pType,
        Proposal.ExecType executable,
        uint256 minVotes,
        uint256 minAgreement,
        uint256[] calldata opinionScales,
        uint256 start,
        uint256 minEnd,
        uint256 maxEnd
    ) external view returns (bool);

    /// @notice Verify proposal contract
    /// @dev Each proposal type has a template to which the data in proposal must correspond
    /// @param pType The type of the template
    /// @param propAddr The address of the proposal contract
    /// @return true if the proposal contract is valid
    function verifyProposalContract(uint256 pType, address propAddr) external view returns (bool);
}
