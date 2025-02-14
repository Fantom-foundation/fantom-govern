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

    constructor(address _govAddress, address _sfcAddress) public {
        gov = Governance(_govAddress);
        sfcAddress = _sfcAddress;
    }

    /// @notice create a new SlashingRefundProposal
    /// @param __validatorID The ID of the validator
    /// @param __description The description of the proposal
    /// @param __minVotes The minimum number of votes required
    /// @param __minAgreement The minimum agreement required
    /// @param __start The start time
    /// @param __minEnd The minimum end time
    /// @param __maxEnd The maximum end time
    function create(
        uint256 __validatorID,
        string calldata __description,
        uint256 __minVotes,
        uint256 __minAgreement,
        uint256 __start,
        uint256 __minEnd,
        uint256 __maxEnd
    ) external payable {
        require(ISFC(sfcAddress).isSlashed(__validatorID), "validator isn't slashed");
        SlashingRefundProposal proposal = new SlashingRefundProposal(
            __validatorID,
            __description,
            __minVotes,
            __minAgreement,
            __start,
            __minEnd,
        __maxEnd,
            sfcAddress,
            address(0)
        );
        proposal.transferOwnership(msg.sender);

        unlockedFor = address(proposal);
        gov.createProposal{value: msg.value}(address(proposal));
        unlockedFor = address(0);
    }
}
