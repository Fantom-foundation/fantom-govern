pragma solidity ^0.5.0;

import "../common/SafeMath.sol";
import "../governance/Governance.sol";
import "../proposal/NetworkParameterProposal.sol";
import "../verifiers/ScopedVerifier.sol";

contract NetworkParameterProposalFactory is ScopedVerifier {
    using SafeMath for uint256;
    Governance internal gov;
    address internal constsAddress;
    address public lastNetworkProposal;

    constructor(address _governance, address _constsAddress) public {
        gov = Governance(_governance);
        constsAddress = _constsAddress;
    }

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
        gov.createProposal.value(msg.value)(address(proposal));
        unlockedFor = address(0);
    }
}