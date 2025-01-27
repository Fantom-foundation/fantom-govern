// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../common/SafeMath.sol";
import "../governance/Governance.sol";
import "../proposal/NetworkParameterProposal.sol";
import "../verifiers/ScopedVerifier.sol";

/// @notice NetworkParameterProposalFactory is a factory contract to create NetworkParameterProposal
contract NetworkParameterProposalFactory is ScopedVerifier {
    using SafeMath for uint256;
    Governance internal _gov;
    address public constsAddress; // address of the Constants contract
    address public lastNetworkProposal; // address of the last created NetworkParameterProposal

    constructor(address _governance, address _constsAddress) {
        _gov = Governance(_governance);
        constsAddress = _constsAddress;
    }

    /// @notice create a new NetworkParameterProposal
    /// @param description The description of the proposal
    /// @param methodID The method ID of the proposal
    /// @param optionVals The option values of the proposal
    /// @param minVotes The minimum number of votes required
    /// @param minAgreement The minimum agreement required
    /// @param start The start time
    /// @param minEnd The minimum end time
    /// @param maxEnd The maximum end time
    function create(
        string memory description,
        uint8 methodID,
        uint256[] memory optionVals,
        uint256 minVotes,
        uint256 minAgreement,
        uint256 start,
        uint256 minEnd,
        uint256 maxEnd
    ) public payable {
        NetworkParameterProposal proposal = new NetworkParameterProposal(
            description,
            methodID,
            optionVals,
            constsAddress,
            minVotes,
            minAgreement,
            start,
            minEnd,
            maxEnd,
            address(0));
        proposal.transferOwnership(msg.sender);
        lastNetworkProposal = address(proposal);

        unlockedFor = address(proposal);
        _gov.createProposal{value: msg.value}(address(proposal));
        unlockedFor = address(0);
    }
}