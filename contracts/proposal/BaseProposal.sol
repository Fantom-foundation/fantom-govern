pragma solidity ^0.5.0;

import "../common/SafeMath.sol";
import "../proposal/IProposal.sol";
import "../proposal/IProposalVerifier.sol";

/**
 * @dev A base for any proposal
 */ 
contract BaseProposal is IProposal {
    using SafeMath for uint256;

    string _name;
    string _description;
    bytes32[] _options;

    uint256 _minVotes;

    uint256 _start;
    uint256 _minEnd;
    uint256 _maxEnd;

    // verifyProposalParams passes proposal parameters to a given verifier
    function verifyProposalParams(address verifier) public view returns (bool) {
        IProposalVerifier proposalVerifier = IProposalVerifier(verifier);
        return proposalVerifier.verifyProposalParams(pType(), executable(), minVotes(), votingStartTime(), votingMinEndTime(), votingMaxEndTime());
    }

    function pType() public view returns (uint256) {
        require(false, "must be overridden");
        return 0;
    }

    function executable() public view returns (bool) {
        require(false, "must be overridden");
        return false;
    }

    function minVotes() public view returns (uint256) {
        return _minVotes;
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

    function options() public view returns (bytes32[] memory) {
        return _options;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function description() public view returns (string memory) {
        return _description;
    }

    function execute(address, uint256) external {
        require(false, "not executable");
    }
}
