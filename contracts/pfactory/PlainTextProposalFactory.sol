pragma solidity ^0.5.0;

import "../governance/Governance.sol";
import "../proposal/PlainTextProposal.sol";
import "../verifiers/ScopedVerifier.sol";

/// @dev PlainTextProposalFactory is a factory contract to create PlainTextProposal
contract PlainTextProposalFactory is ScopedVerifier {
    Governance internal gov;
    constructor(address _govAddress) public {
        gov = Governance(_govAddress);
    }

    /// @dev create creates a new PlainTextProposal
    /// @param __name The name of the proposal
    /// @param __description The description of the proposal
    /// @param __options The options of the proposal
    /// @param __minVotes The minimum number of votes required
    /// @param __minAgreement The minimum agreement required
    /// @param __start The start time
    /// @param __minEnd The minimum end time
    /// @param __maxEnd The maximum end time
    function create(string calldata __name, string calldata __description, bytes32[] calldata __options,
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd) payable external {
        // use memory to avoid stack overflow
        uint256[] memory params = new uint256[](5);
        params[0] = __minVotes;
        params[1] = __minAgreement;
        params[2] = __start;
        params[3] = __minEnd;
        params[4] = __maxEnd;

        PlainTextProposal proposal = new PlainTextProposal(__name, __description, __options,
            params[0], params[1], params[2], params[3], params[4], address(0));
        proposal.transferOwnership(msg.sender);

        unlockedFor = address(proposal);
        gov.createProposal.value(msg.value)(address(proposal));
        unlockedFor = address(0);
    }
}
