// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IProposal} from "./IProposal.sol";
import {IProposalVerifier} from "../../verifiers/IProposalVerifier.sol";
import {Proposal} from "../../governance/Proposal.sol";

/// @notice A base for any proposal
contract BaseProposal is IProposal {
    string public _name;
    string public _description;
    bytes32[]public  _options;

    uint256 public _minVotes;
    uint256 public _minAgreement;
    // Static scale for front end
    // i.e. [1, 2, 3, 4] will result in the scale being divided into 4 parts
    // where 1 means the least agreement and 4 means the most
    uint256[] public _opinionScales;

    uint256 public _start; // Start of the voting
    uint256 public _minEnd; // Minimal end time of the voting
    uint256 public _maxEnd; // Maxinal end time of the voting

    /// @notice Verify the parameters of the proposal using a given verifier.
    /// @param verifier The address of the verifier contract.
    /// @return bool indicating whether the proposal parameters are valid.
    function verifyProposalParams(address verifier) public view returns (bool) {
        IProposalVerifier proposalVerifier = IProposalVerifier(verifier);
        return proposalVerifier.verifyProposalParams(pType(), executable(), minVotes(), minAgreement(), opinionScales(), votingStartTime(), votingMinEndTime(), votingMaxEndTime());
    }

    function pType() public virtual view returns (uint256) {
        require(false, "must be overridden");
        return uint256(StdProposalTypes.NOT_INIT);
    }

    function executable() public virtual view returns (Proposal.ExecType) {
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

    function votingStartTime() public virtual view returns (uint256) {
        return block.timestamp + _start;
    }

    function votingMinEndTime() public virtual view returns (uint256) {
        return votingStartTime() + _minEnd;
    }

    function votingMaxEndTime() public virtual view returns (uint256) {
        return votingStartTime() + _maxEnd;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function description() public view returns (string memory) {
        return _description;
    }

    function executeDelegateCall(address, uint256) external virtual {
        require(false, "not delegatecall-executable");
    }

    function executeCall(uint256) external virtual {
        require(false, "not call-executable");
    }
}
