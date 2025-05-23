// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IProposal} from "../../interfaces/IProposal.sol";
import {IProposalVerifier} from "../../interfaces/IProposalVerifier.sol";
import {Proposal} from "../../governance/Proposal.sol";

/// @notice A base for any proposal
contract BaseProposal is IProposal {
    string internal _name;
    string internal _description;
    bytes32[] internal  _options;

    uint256 internal _minVotes;
    uint256 internal _minAgreement;
    // Static scale for front end
    // i.e. [1, 2, 3, 4] will result in the scale being divided into 4 parts
    // where 1 means the least agreement and 4 means the most
    uint256[] internal _opinionScales;

    uint256 internal _start; // Start of the voting
    uint256 internal _minEnd; // Minimal end time of the voting
    uint256 internal _maxEnd; // Maximal end time of the voting

    error MustBeOverwritten(); // when a function is not overwritten
    error NotDelegateCallExecutable(); // when proposals ExecuteDelegateCall is called but it is not delegate call proposal
    error NotCallExecutable(); // when proposals ExecuteCall is called but it is not a call

    /// @notice Verify the parameters of the proposal using a given verifier.
    /// @param verifier The address of the verifier contract.
    function verifyProposalParams(address verifier) public view {
        IProposalVerifier proposalVerifier = IProposalVerifier(verifier);
        proposalVerifier.verifyProposalParams(pType(), executable(), minVotes(), minAgreement(), opinionScales(), votingStartTime(), votingMinEndTime(), votingMaxEndTime());
    }

    function pType() public virtual view returns (uint256) {
        revert MustBeOverwritten();
        return uint256(StdProposalTypes.NOT_INIT);
    }

    function executable() public virtual view returns (Proposal.ExecType) {
        revert MustBeOverwritten();
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
        revert NotDelegateCallExecutable();
    }

    function executeCall(uint256) external virtual {
        revert NotCallExecutable();
    }
}
