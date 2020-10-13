pragma solidity ^0.5.0;

import "../base/BaseProposal.sol";

contract ExplicitProposal is BaseProposal {
    using SafeMath for uint256;

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

    function pType() public view returns (uint256) {
        return _pType;
    }

    function executable() public view returns (Proposal.ExecType) {
        return _exec;
    }

    function votingStartTime() public view returns (uint256) {
        return _start;
    }

    function votingMinEndTime() public view returns (uint256) {
        return _minEnd;
    }

    function votingMaxEndTime() public view returns (uint256) {
        return _maxEnd;
    }

    function execute_delegatecall(address, uint256) external {}
    function execute_call(uint256) external {}
}
