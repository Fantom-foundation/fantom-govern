pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../common/SafeMath.sol";
import "../governance/Governance.sol";
import "../proposal/NetworkParameterProposal.sol";
import "../verifiers/ScopedVerifier.sol";

contract NetworkParameterProposalFactory is ScopedVerifier {
    using SafeMath for uint256;
    Governance internal gov;
    address public sfc;
    address public lastNetworkProposal;

    constructor(address _governance, address _sfc) public {
        gov = Governance(_governance);
        sfc = _sfc;
    }

    function create(
        string[] memory __strings,
        bytes32[] memory __options,
        uint256[] memory __params,
        uint256[] memory __optionsList,
        Proposal.ExecType __exec,
        address verifier
    ) public payable {
        require(msg.value >= gov.proposalFee(), "insufficient fee");

        _create(__strings, __options, __params, __optionsList, __exec, verifier);
    }

    function _create(
        string[] memory __strings,
        bytes32[] memory __options,
        uint256[] memory __params,
        uint256[] memory __optionsList,
        Proposal.ExecType __exec,
        address verifier
    ) internal {
        NetworkParameterProposal proposal = new NetworkParameterProposal(
            __strings, 
            __options, 
            __params, 
            __optionsList, 
            __exec,
            sfc,
            verifier);
        proposal.transferOwnership(msg.sender);
        lastNetworkProposal = address(proposal);

        gov.createProposal.value(msg.value)(address(proposal));
    }

}