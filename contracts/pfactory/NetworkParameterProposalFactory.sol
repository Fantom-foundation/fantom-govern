// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Governance} from "../governance/Governance.sol";
import {NetworkParameterProposal} from "../proposal/NetworkParameterProposal.sol";
import {ScopedVerifier} from "../verifiers/ScopedVerifier.sol";

/// @notice NetworkParameterProposalFactory is a factory contract to create NetworkParameterProposal
contract NetworkParameterProposalFactory is ScopedVerifier {
    Governance internal gov;
    address internal constsAddress; // address of the Constants contract
    address public lastNetworkProposal; // address of the last created NetworkParameterProposal

    constructor(address _governance, address _constsAddress) {
        gov = Governance(_governance);
        constsAddress = _constsAddress;
    }

    /// @notice create a new NetworkParameterProposal
    /// @param __description The description of the proposal
    /// @param __methodID The method ID of the proposal
    /// @param __optionVals The option values of the proposal
    /// @param __minVotes The minimum number of votes required
    /// @param __minAgreement The minimum agreement required
    /// @param __start The start time
    /// @param __minEnd The minimum end time
    /// @param __maxEnd The maximum end time
    function create(
        string memory __description,
        uint8 __methodID,
        uint256[] memory __optionVals,
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd
    ) public payable {
        NetworkParameterProposal proposal = new NetworkParameterProposal(
            __description,
            __methodID,
            __optionVals,
            constsAddress,
            __minVotes,
            __minAgreement,
            __start,
            __minEnd,
            __maxEnd,
            address(0));
        proposal.transferOwnership(msg.sender);
        lastNetworkProposal = address(proposal);

        unlockedFor = address(proposal);
        gov.createProposal{value: msg.value}(address(proposal));
        unlockedFor = address(0);
    }
}