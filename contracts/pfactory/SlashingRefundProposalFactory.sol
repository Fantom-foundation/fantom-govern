pragma solidity ^0.5.0;

import "../governance/Governance.sol";
import "../proposal/SlashingRefundProposal.sol";
import "../verifiers/ScopedVerifier.sol";

contract SlashingRefundProposalFactory is ScopedVerifier {
    Governance internal gov;
    address internal sfcAddress;
    constructor(address _govAddress, address _sfcAddress) public {
        gov = Governance(_govAddress);
        sfcAddress = _sfcAddress;
    }

    function create(uint256 __validatorID, string calldata __description,
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd) payable external {
        // use memory to avoid stack overflow
        uint256[] memory params = new uint256[](5);
        params[0] = __minVotes;
        params[1] = __minAgreement;
        params[2] = __start;
        params[3] = __minEnd;
        params[4] = __maxEnd;
        _create(__validatorID, __description, params);
    }

    function _create(uint256 __validatorID, string memory __description, uint256[] memory params) internal {
        require(SFC(sfcAddress).isSlashed(__validatorID), "validator isn't slashed");
        SlashingRefundProposal proposal = new SlashingRefundProposal(__validatorID, __description,
            params[0], params[1], params[2], params[3], params[4], sfcAddress, address(0));
        proposal.transferOwnership(msg.sender);

        unlockedFor = address(proposal);
        gov.createProposal.value(msg.value)(address(proposal));
        unlockedFor = address(0);
    }
}
