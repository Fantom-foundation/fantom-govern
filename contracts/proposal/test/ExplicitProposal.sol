// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {BaseProposal} from "../base/BaseProposal.sol";
import {Proposal} from "../../governance/Proposal.sol";

/// @dev A proposal with all parameters explicitly set
/// @dev Used for testing purposes
contract ExplicitProposal is BaseProposal {
    uint256 _pType;
    Proposal.ExecType _exec;

    function setType(uint256 v) public {
        _pType = v;
    }

    function setMinVotes(uint256 v) public {
        _minVotes = v;
    }

    function setMinAgreement(uint256 v) public {
        _minAgreement = v;
    }

    function setOpinionScales(uint256[] memory v) public {
        _opinionScales = v;
    }

    function setVotingStartTime(uint256 v) public {
        _start = v;
    }

    function setVotingMinEndTime(uint256 v) public {
        _minEnd = v;
    }

    function setVotingMaxEndTime(uint256 v) public {
        _maxEnd = v;
    }

    function setExecutable(Proposal.ExecType v) public {
        _exec = v;
    }

    function setOptions(bytes32[] memory v) public {
        _options = v;
    }

    function setName(string memory v) public {
        _name = v;
    }

    function setDescription(string memory v) public {
        _description = v;
    }

    function pType() public view override returns (uint256) {
        return _pType;
    }

    function executable() public override view returns (Proposal.ExecType) {
        return _exec;
    }

    function votingStartTime() public override view returns (uint256) {
        return _start;
    }

    function votingMinEndTime() public override view returns (uint256) {
        return _minEnd;
    }

    function votingMaxEndTime() public override view returns (uint256) {
        return _maxEnd;
    }

    function execute_delegatecall(address, uint256) external override {}
    function execute_call(uint256) external override {}
}
