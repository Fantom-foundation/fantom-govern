// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Governance} from "../governance/Governance.sol";
import {PlainTextProposal} from "../proposal/PlainTextProposal.sol";
import {ScopedVerifier} from "../verifiers/ScopedVerifier.sol";

/// @notice PlainTextProposalFactory is a factory contract to create PlainTextProposal
contract PlainTextProposalFactory is ScopedVerifier {
    Governance internal gov;
    // @dev used to avoid 'Stack too deep' error
    struct Params {
        string name;
        string description;
        bytes32[] options;
        uint256 minVotes;
        uint256 minAgreement;
        uint256 start;
        uint256 minEnd;
        uint256 maxEnd;
    }

    constructor(address _govAddress) public {
        gov = Governance(_govAddress);
    }

    /// @notice create a new PlainTextProposal
    /// @param __name The name of the proposal
    /// @param __description The description of the proposal
    /// @param __options The options of the proposal
    /// @param __minVotes The minimum number of votes required
    /// @param __minAgreement The minimum agreement required
    /// @param __start The start time
    /// @param __minEnd The minimum end time
    /// @param __maxEnd The maximum end time
    function create(
        string calldata __name,
        string calldata __description,
        bytes32[] calldata __options,
        uint256 __minVotes,
        uint256 __minAgreement,
        uint256 __start,
        uint256 __minEnd,
        uint256 __maxEnd
    ) payable external payable {
        Params memory p = Params(
            __name,
            __description,
            __options,
            __minVotes,
            __minAgreement,
            __start,
            __minEnd,
            __maxEnd
        );
        _create(p);
    }

    /// @dev internal function to create a new PlainTextProposal
    /// @param p The parameters of the proposal
    function _create(
        Params memory p
    ) internal {
        PlainTextProposal proposal = new PlainTextProposal(
            p.name,
            p.description,
            p.options,
            p.minVotes,
            p.minAgreement,
            p.start,
            p.minEnd,
            p.maxEnd,
            address(0)
        );
        proposal.transferOwnership(msg.sender);

        unlockedFor = address(proposal);
        gov.createProposal{value: msg.value}(address(proposal));
        unlockedFor = address(0);
    }
}
