// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Proposal} from "../governance/Proposal.sol";


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
    function verifyProposalParams(
        uint256 pType,
        Proposal.ExecType executable,
        uint256 minVotes,
        uint256 minAgreement,
        uint256[] calldata opinionScales,
        uint256 start,
        uint256 minEnd,
        uint256 maxEnd
    ) external view;

    /// @notice Verify proposal contract
    /// @dev Each proposal type has a template to which the data in proposal must correspond
    /// @param pType The type of the template
    /// @param propAddr The address of the proposal contract
    function verifyProposalContract(uint256 pType, address propAddr) external view;
}
