// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../governance/Governance.sol";
import "../proposal/SlashingRefundProposal.sol";
import "../verifiers/ScopedVerifier.sol";

/// @notice SlashingRefundProposalFactory is a factory contract to create SlashingRefundProposal
contract SlashingRefundProposalFactory is ScopedVerifier {
    Governance internal gov;
    address internal sfcAddress;
    constructor(address _govAddress, address _sfcAddress) {
        gov = Governance(_govAddress);
        sfcAddress = _sfcAddress;
    }

    /// @notice create a new SlashingRefundProposal
    /// @param validatorID The ID of the validator
    /// @param description The description of the proposal
    /// @param minVotes The minimum number of votes required
    /// @param minAgreement The minimum agreement required
    /// @param start The start time
    /// @param minEnd The minimum end time
    /// @param maxEnd The maximum end time
    function create(
        uint256 validatorID,
        string calldata description,
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
        _create(validatorID, description, params);
    }

    function _create(
        uint256 validatorID,
        string memory description,
        uint256[] memory params
    ) internal {
        require(SFC(sfcAddress).isSlashed(validatorID), "validator isn't slashed");
        SlashingRefundProposal proposal = new SlashingRefundProposal(
            validatorID,
            description,
            params[0],
            params[1],
            params[2],
            params[3],
            params[4],
            sfcAddress,
            address(0)
        );
        proposal.transferOwnership(msg.sender);

        unlockedFor = address(proposal);
        gov.createProposal{value: msg.value}(address(proposal));
        unlockedFor = address(0);
    }
}
