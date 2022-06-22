pragma solidity ^0.5.0;

import "../../common/SafeMath.sol";
import "./IProposal.sol";
import "../../verifiers/IProposalVerifier.sol";
import "../../governance/Proposal.sol";

/**
 * @dev A base for any proposal
 */
contract BaseProposal is IProposal {
    using SafeMath for uint256;

    string _name;
    string _description;
    bytes32[] _options;

    uint256 _minVotes;
    uint256 _minAgreement;
    uint256[] _opinionScales;

    uint256 _start;
    uint256 _minEnd;
    uint256 _maxEnd;

    // verifyProposalParams passes proposal parameters to a given verifier
    function verifyProposalParams(address verifier) public view returns (bool) {
        IProposalVerifier proposalVerifier = IProposalVerifier(verifier);
        return proposalVerifier.verifyProposalParams(pType(), executable(), minVotes(), minAgreement(), opinionScales(), votingStartTime(), votingMinEndTime(), votingMaxEndTime());
    }

    function pType() public view returns (uint256) {
        require(false, "must be overridden");
        return uint256(StdProposalTypes.NOT_INIT);
    }

    function executable() public view returns (Proposal.ExecType) {
        require(false, "must be overridden");
        return Proposal.ExecType.NONE;
    }

    function minVotes() public view returns (uint256) {
        return _minVotes;
    }

    function minAgreement() public view returns (uint256) {
        return _minAgreement;
    }

    function opinionScales() public view returns (uint256[] memory) {
        return _opinionScales;
    }

    function options() public view returns (bytes32[] memory) {
        return _options;
    }

    function votingStartTime() public view returns (uint256) {
        return block.timestamp + _start;
    }

    function votingMinEndTime() public view returns (uint256) {
        return votingStartTime() + _minEnd;
    }

    function votingMaxEndTime() public view returns (uint256) {
        return votingStartTime() + _maxEnd;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function description() public view returns (string memory) {
        return _description;
    }

    function execute_delegatecall(address, uint256) external {
        require(false, "not delegatecall-executable");
    }

    function execute_call(uint256) external {
        require(false, "not call-executable");
    }
}
