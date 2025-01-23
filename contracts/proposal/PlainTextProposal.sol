// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./base/Cancelable.sol";
import "./base/NonExecutableProposal.sol";



/// @dev A plain text proposal
contract PlainTextProposal is NonExecutableProposal, Cancelable {
    constructor(string memory __name, string memory __description, bytes[] memory __options,
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
            require(verifyProposalParams(verifier), "failed verification");
        }
    }
}