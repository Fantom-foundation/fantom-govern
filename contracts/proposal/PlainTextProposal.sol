pragma solidity ^0.5.0;

import "./BaseProposal.sol";
import "./Cancelable.sol";

/**
 * @dev PlainText proposal
 */
contract PlainTextProposal is BaseProposal, Cancelable {
    constructor(string memory __name, string memory __description, bytes32[] memory __options,
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd, address verifier) public {
        _name = __name;
        _description = __description;
        _options = __options;
        _minVotes = __minVotes;
        _minAgreement = __minAgreement;
        _opinionScales = [0, 1, 2, 3, 4];
        _start = __start;
        _minEnd = __minEnd;
        _maxEnd = __maxEnd;
        // verify the proposal right away to avoid deploying a wrong proposal
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed validation");
        }
    }

    // Returns proposal type as a plain text proposal
    function pType() public view returns (uint256) {
        return uint256(StdProposalTypes.PLAIN_TEXT);
    }

    // Returns execution type
    function executable() public view returns (Proposal.ExecType) {
        return Proposal.ExecType.NONE;
    }
}