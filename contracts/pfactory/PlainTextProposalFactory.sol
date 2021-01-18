pragma solidity ^0.5.0;

import "../governance/Governance.sol";
import "../proposal/PlainTextProposal.sol";
import "../verifiers/ScopedVerifier.sol";

contract PlainTextProposalFactory is ScopedVerifier {
    Governance internal gov;
    constructor(address _govAddress) public {
        gov = Governance(_govAddress);
    }

    function create(string calldata __name, string calldata __description, bytes32[] calldata __options,
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd) payable external {
        // use memory to avoid stack overflow
        uint256[] memory params = new uint256[](5);
        params[0] = __minVotes;
        params[1] = __minAgreement;
        params[2] = __start;
        params[3] = __minEnd;
        params[4] = __maxEnd;
        _create(__name, __description, __options, params);
    }

    function _create(string memory __name, string memory __description, bytes32[] memory __options, uint256[] memory params) internal {
        PlainTextProposal proposal = new PlainTextProposal(__name, __description, __options,
            params[0], params[1], params[2], params[3], params[4], address(0));
        proposal.transferOwnership(msg.sender);

        unlockedFor = address(proposal);
        gov.createProposal.value(msg.value)(address(proposal));
        unlockedFor = address(0);
    }
}
