// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ISFC} from "../interfaces/ISFC.sol";
import {Governance} from "../governance/Governance.sol";
import {ScopedVerifier} from "../verifiers/ScopedVerifier.sol";
import {SlashingRefundProposal} from "../proposal/SlashingRefundProposal.sol";

/// @notice SlashingRefundProposalFactory is a factory contract to create SlashingRefundProposal
contract SlashingRefundProposalFactory is ScopedVerifier {
    Governance internal gov;
    address internal sfcAddress;

    error ValidatorNotSlashed(); // thrown when proposing not slashed validator

    constructor(address govAddress, address _sfcAddress) public {
        gov = Governance(govAddress);
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
    ) external payable {
        if (!ISFC(sfcAddress).isSlashed(validatorID)) {
            revert ValidatorNotSlashed();
        }
        SlashingRefundProposal proposal = new SlashingRefundProposal(
            validatorID,
            description,
            minVotes,
            minAgreement,
            start,
            minEnd,
            maxEnd,
            sfcAddress,
            address(0)
        );
        proposal.transferOwnership(msg.sender);

        unlockedFor = address(proposal);
        gov.createProposal{value: msg.value}(address(proposal));
        unlockedFor = address(0);
    }
}
