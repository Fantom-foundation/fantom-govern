pragma solidity ^0.5.0;

import "../proposal/ProposalTypes.sol";
import "../proposal/BaseProposal.sol";

/**
 * @dev PlainText proposal
 */
contract PlainTextProposal is BaseProposal {
    constructor(string memory __name, string memory __description, bytes32[] memory __options,
        uint256 __minVotes, uint256 __start, uint256 __minEnd, uint256 __maxEnd, address verifier) public {
        _name = __name;
        _description = __description;
        _options = __options;
        _minVotes = __minVotes;
        _start = __start;
        _minEnd = __minEnd;
        _maxEnd = __maxEnd;
        // verify the proposal right away
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed validation");
        }
    }

    // Returns proposal type as a plain text proposal
    function pType() public view returns (uint256) {
        return StdProposalTypes.plaintext();
    }

    // Returns false as it is not executable
    function executable() public view returns (bool) {
        return false;
    }
}