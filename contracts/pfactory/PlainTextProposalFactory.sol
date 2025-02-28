// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Governance} from "../governance/Governance.sol";
import {PlainTextProposal} from "../proposal/PlainTextProposal.sol";
import {ScopedVerifier} from "../verifiers/ScopedVerifier.sol";

/// @notice PlainTextProposalFactory is a factory contract to create PlainTextProposal
contract PlainTextProposalFactory is ScopedVerifier {
    Governance internal gov;
    constructor(address govAddress) public {
        gov = Governance(govAddress);
    }

    /// @notice create a new PlainTextProposal
    /// @param name The name of the proposal
    /// @param description The description of the proposal
    /// @param options The options of the proposal
    /// @param minVotes The minimum number of votes required
    /// @param minAgreement The minimum agreement required
    /// @param start The start time
    /// @param minEnd The minimum end time
    /// @param maxEnd The maximum end time
    function create(
        string memory name,
        string memory description,
        bytes32[] memory options,
        uint256 minVotes,
        uint256 minAgreement,
        uint256 start,
        uint256 minEnd,
        uint256 maxEnd
    ) external payable {
        PlainTextProposal proposal = new PlainTextProposal(
            name,
            description,
            options,
            minVotes,
            minAgreement,
            start,
            minEnd,
            maxEnd,
            address(0)
        );
        proposal.transferOwnership(msg.sender);

        unlockedFor = address(proposal);
        gov.createProposal{value: msg.value}(address(proposal));
        unlockedFor = address(0);
    }
}
