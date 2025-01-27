// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./base/Cancelable.sol";
import "./base/NonExecutableProposal.sol";

/// @notice A plain text proposal
contract PlainTextProposal is NonExecutableProposal, Cancelable {
    constructor(
        string memory _name,
        string memory _description,
        bytes32[] memory _options,
        uint256 _minVotes,
        uint256 _minAgreement,
        uint256 _start,
        uint256 _minEnd,
        uint256 _maxEnd,
        address verifier
    ) {
        _name = _name;
        _description = _description;
        _options = _options;
        _minVotes = _minVotes;
        _minAgreement = _minAgreement;
        _opinionScales = [0, 1, 2, 3, 4];
        _start = _start;
        _minEnd = _minEnd;
        _maxEnd = _maxEnd;
        // verify the proposal right away to avoid deploying a wrong proposal
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed verification");
        }
    }
}