// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Decimal} from "../common/Decimal.sol";
import {IProposal} from "../proposal/base/IProposal.sol";
import {IProposalVerifier} from "./IProposalVerifier.sol";
import {Version} from "../version/Version.sol";
import {Proposal} from "../governance/Proposal.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// @notice A storage of current proposal templates. Any new proposal will be verified against the stored template of its type.
// Verification checks for parameters and calls additional verifier (if any).
// Supposed to be owned by the governance contract
contract ProposalTemplates is IProposalVerifier, OwnableUpgradeable, Version {
    /// @notice Event emitted when a new template is added
    /// @param pType The type of the template
    event AddedTemplate(uint256 pType);
    /// @notice Event emitted when a template is erased
    /// @param pType The type of the template
    event ErasedTemplate(uint256 pType);

    // Stored data for a proposal template
    struct ProposalTemplate {
        string name;
        address verifier; // used as additional verifier
        Proposal.ExecType executable; // proposal execution type when proposal gets resolved
        uint256 minVotes; // minimum voting turnout (ratio)
        uint256 minAgreement; // minimum allowed minAgreement
        uint256[] opinionScales; // Each opinion scale defines an exact measure of agreement which voter may choose
        uint256 minVotingDuration; // minimum duration of the voting
        uint256 maxVotingDuration; // maximum duration of the voting
        uint256 minStartDelay; // minimum delay of the voting (i.e. must start with a delay)
        uint256 maxStartDelay; // maximum delay of the voting (i.e. must start sooner)
    }

    // templates library
    mapping(uint256 => ProposalTemplate) proposalTemplates; // proposal type => ProposalTemplate

    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }

    // exists returns true if proposal template is present
    function exists(uint256 pType) public view returns (bool) {
        return bytes(proposalTemplates[pType].name).length != 0;
    }

    // get returns proposal template
    function get(uint256 pType) public view returns (
        string memory name,
        address verifier,
        Proposal.ExecType executable,
        uint256 minVotes,
        uint256 minAgreement,
        uint256[] memory opinionScales,
        uint256 minVotingDuration,
        uint256 maxVotingDuration,
        uint256 minStartDelay,
        uint256 maxStartDelay
    ) {
        ProposalTemplate storage t = proposalTemplates[pType];
        return (
            t.name,
            t.verifier,
            t.executable,
            t.minVotes,
            t.minAgreement,
            t.opinionScales,
            t.minVotingDuration,
            t.maxVotingDuration,
            t.minStartDelay,
            t.maxStartDelay
        );
    }

    /// @notice adds a new template to the library
    /// @param pType The type of the template - must not already exist
    /// @param name The name of the template
    /// @param verifier The address of the verifier contract
    /// @param executable The type of execution
    /// @param minVotes The minimum number of votes required
    /// @param minAgreement The minimum agreement required
    /// @param opinionScales The opinion scales
    /// @param minVotingDuration The minimum voting duration
    /// @param maxVotingDuration The maximum voting duration
    /// @param minStartDelay The minimum start delay
    /// @param maxStartDelay The maximum start delay
    function addTemplate(
        uint256 pType,
        string memory name,
        address verifier,
        Proposal.ExecType executable,
        uint256 minVotes,
        uint256 minAgreement,
        uint256[] calldata opinionScales,
        uint256 minVotingDuration,
        uint256 maxVotingDuration,
        uint256 minStartDelay,
        uint256 maxStartDelay
    ) external onlyOwner {
        ProposalTemplate storage template = proposalTemplates[pType];
        // empty name is a marker of non-existing template
        require(bytes(name).length != 0, "empty name");
        require(!exists(pType), "template already exists");
        require(opinionScales.length != 0, "empty opinions");
        require(checkNonDecreasing(opinionScales), "wrong order of opinions");
        require(opinionScales[opinionScales.length - 1] != 0, "all opinions are zero");
        require(minVotes <= Decimal.unit(), "minVotes > 1.0");
        require(minAgreement <= Decimal.unit(), "minAgreement > 1.0");
        template.verifier = verifier;
        template.name = name;
        template.executable = executable;
        template.minVotes = minVotes;
        template.minAgreement = minAgreement;
        template.opinionScales = opinionScales;
        template.minVotingDuration = minVotingDuration;
        template.maxVotingDuration = maxVotingDuration;
        template.minStartDelay = minStartDelay;
        template.maxStartDelay = maxStartDelay;

        emit AddedTemplate(pType);
    }

    /// @notice erases a template from the library - Only the owner can erase a template
    /// @param pType The type of the template
    function eraseTemplate(uint256 pType) external onlyOwner {
        require(exists(pType), "template doesn't exist");
        delete (proposalTemplates[pType]);

        emit ErasedTemplate(pType);
    }

    /// @notice Verify proposal parameters
    /// @param pType The type of the template
    /// @param executable The type of execution
    /// @param minVotes The minimum number of votes required
    /// @param minAgreement The minimum agreement required
    /// @param opinionScales The opinion scales
    /// @param start The start time
    /// @param minEnd The minimum end time
    /// @param maxEnd The maximum end time
    /// @return true if the proposal parameters are valid
    function verifyProposalParams(
        uint256 pType,
        Proposal.ExecType executable,
        uint256 minVotes,
        uint256 minAgreement,
        uint256[] calldata opinionScales,
        uint256 start,
        uint256 minEnd,
        uint256 maxEnd
    ) external view returns (bool) {
        if (!exists(pType)) {
            // non-existing template
            return false;
        }
        ProposalTemplate memory template = proposalTemplates[pType];
        if (executable != template.executable) {
            // inconsistent executable flag
            return false;
        }
        if (minVotes < template.minVotes) {
            // turnout is too small
            return false;
        }
        if (minVotes > Decimal.unit()) {
            // turnout is bigger than 100%
            return false;
        }
        if (minAgreement < template.minAgreement) {
            // quorum is too small
            return false;
        }
        if (minAgreement > Decimal.unit()) {
            // quorum is bigger than 100%
            return false;
        }
        if (opinionScales.length != template.opinionScales.length) {
            // wrong opinion scales
            return false;
        }
        for (uint256 i = 0; i < opinionScales.length; i++) {
            if (opinionScales[i] != template.opinionScales[i]) {
                // wrong opinion scales
                return false;
            }
        }
        if (start < block.timestamp) {
            // start in the past
            return false;
        }
        if (start > minEnd) {
            // inconsistent data
            return false;
        }
        if (minEnd > maxEnd) {
            // inconsistent data
            return false;
        }

        uint256 minDuration = minEnd - start;
        uint256 maxDuration = maxEnd - start;
        uint256 startDelay_ = start - block.timestamp;
        if (minDuration < template.minVotingDuration) {
            // min. voting duration is too short
            return false;
        }
        if (maxDuration > template.maxVotingDuration) {
            // max. voting duration is too long
            return false;
        }
        if (startDelay_ < template.minStartDelay) {
            // voting must start later
            return false;
        }
        if (startDelay_ > template.maxStartDelay) {
            // voting is too distant in future
            return false;
        }
        if (template.verifier == address(0)) {
            // template with no additional verifier
            return true;
        }
        return IProposalVerifier(template.verifier).verifyProposalParams(
            pType,
            executable,
            minVotes,
            minAgreement,
            opinionScales,
            start,
            minEnd,
            maxEnd
        );
    }

    /// @notice Verify proposal contract against its template
    /// @param pType The type of the template
    /// @param propAddr The address of the proposal contract
    /// @return true if the proposal contract is valid
    function verifyProposalContract(uint256 pType, address propAddr) external view returns (bool) {
        if (!exists(pType)) {
            // non-existing template
            return false;
        }
        ProposalTemplate memory template = proposalTemplates[pType];
        if (template.verifier == address(0)) {
            // template with no additional verifier
            return true;
        }
        return IProposalVerifier(template.verifier).verifyProposalContract(pType, propAddr);
    }

    /// @dev Check if array values are monotonically non-decreasing
    /// @param arr The array to check
    /// @return true if the array is monotonically non-decreasing
    function checkNonDecreasing(uint256[] memory arr) internal pure returns (bool) {
        for (uint256 i = 1; i < arr.length; i++) {
            if (arr[i - 1] > arr[i]) {
                return false;
            }
        }
        return true;
    }
}
