// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../governance/Governance.sol";
import "../proposal/PlainTextProposal.sol";
import "../verifiers/ScopedVerifier.sol";

/// @notice PlainTextProposalFactory is a factory contract to create PlainTextProposal
contract PlainTextProposalFactory is ScopedVerifier {
    Governance internal _gov;
    constructor(address govAddress) {
        _gov = Governance(govAddress);
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
        string calldata name,
        string calldata description,
        bytes32[] calldata options,
        uint256 minVotes,
        uint256 minAgreement,
        uint256 start,
        uint256 minEnd,
        uint256 maxEnd
    ) payable external {
        // use memory to avoid stack overflow
        uint256[] memory params = new uint256[](5);
        params[0] = minVotes;
        params[1] = minAgreement;
        params[2] = start;
        params[3] = minEnd;
        params[4] = maxEnd;
        _create(name, description, options, params);
    }

    /// @dev internal function to create a new PlainTextProposal
    /// @param name The name of the proposal
    /// @param description The description of the proposal
    /// @param options The options of the proposal
    /// @param params The parameters of the proposal
    function _create(
        string memory name,
        string memory description,
        bytes32[] memory options,
        uint256[] memory params
    ) internal {
        PlainTextProposal proposal = new PlainTextProposal(
            name,
            description,
            options,

            params[0],
            params[1],
            params[2],
            params[3],
            params[4],
            address(0)
        );
        proposal.transferOwnership(msg.sender);

        unlockedFor = address(proposal);
        _gov.createProposal{value: msg.value}(address(proposal));
        unlockedFor = address(0);
    }
}
