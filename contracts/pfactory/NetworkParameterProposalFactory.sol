// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Governance} from "../governance/Governance.sol";
import {NetworkParameterProposal} from "../proposal/NetworkParameterProposal.sol";
import {ScopedVerifier} from "../verifiers/ScopedVerifier.sol";

/// @notice NetworkParameterProposalFactory is a factory contract to create NetworkParameterProposal
contract NetworkParameterProposalFactory is ScopedVerifier {
    Governance internal gov;
    address internal updaterAddress; // address of the Updater contract
    address public lastNetworkProposal; // address of the last created NetworkParameterProposal

    constructor(address govAddress, address _updaterAddress) {
        gov = Governance(govAddress);
        updaterAddress = _updaterAddress;
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
            updaterAddress,
            minVotes,
            minAgreement,
            start,
            minEnd,
            maxEnd,
            address(0)
        );
        proposal.transferOwnership(msg.sender);
        lastNetworkProposal = address(proposal);

        unlockedFor = address(proposal);
        gov.createProposal{value: msg.value}(address(proposal));
        unlockedFor = address(0);
    }
}