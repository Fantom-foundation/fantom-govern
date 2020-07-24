pragma solidity ^0.5.0;

import "../proposal/BaseProposal.sol";

contract ExplicitProposal is BaseProposal {
    using SafeMath for uint256;

    uint256 _pType;
    bool _executable;

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

    function setExecutable(bool v) public {
        _executable = v;
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

    function executable() public view returns (bool) {
        return _executable;
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

    function execute(address, uint256) external {}
}
