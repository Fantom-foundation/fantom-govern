// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Decimal} from "../common/Decimal.sol";
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
    mapping(uint256 => ProposalTemplate) public proposalTemplates; // proposal type => ProposalTemplate

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

    error EmptyName();
    error TemplateExists(uint256 pType);
    error EmptyOpinions();
    error OpinionsNotSorted();
    error AllOpinionsZero();
    error MinVotesOverflow();
    error MinAgreementOverflow();
    error UnknownTemplate(uint256 pType);
    error ExecutableTypeMismatch(Proposal.ExecType got, Proposal.ExecType want);
    error MinVotesTooSmall(uint256 got, uint256 min);
    error MinVotesTooLarge(uint256 got, uint256 max);
    error MinAgreementTooSmall(uint256 got, uint256 min);
    error MinAgreementTooLarge(uint256 got, uint256 max);
    error OpinionScalesLengthMismatch(uint256 got, uint256 want);
    error OpinionScalesMismatch(uint256 got, uint256 want, uint256 idx);
    error StartIsInThePast();
    error StartIsAfterMinEnd(uint256 start, uint256 minEnd);
    error MinEndIsAfterMaxEnd(uint256 minEnd, uint256 maxEnd);
    error MinDurationIsTooShort(uint256 got, uint256 min);
    error MaxDurationIsTooLong(uint256 got, uint256 max);
    error StartDelayIsTooSmall(uint256 got, uint256 min);
    error StartDelayIsTooLarge(uint256 got, uint256 max);

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
        if (bytes(name).length == 0) {
            revert EmptyName();
        }
        if (exists(pType)) {
            revert TemplateExists(pType);
        }
        if (opinionScales.length == 0) {
            revert EmptyOpinions();
        }
        if (!checkNonDecreasing(opinionScales)) {
            revert OpinionsNotSorted();
        }
        if (opinionScales[opinionScales.length - 1] == 0) {
            revert AllOpinionsZero();
        }
        if (minVotes > Decimal.unit()) {
            revert MinVotesOverflow();
        }
        if (minAgreement > Decimal.unit()) {
            revert MinAgreementOverflow();
        }
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
        if (exists(pType)) {
            revert UnknownTemplate(pType);
        }
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
    function verifyProposalParams(
        uint256 pType,
        Proposal.ExecType executable,
        uint256 minVotes,
        uint256 minAgreement,
        uint256[] calldata opinionScales,
        uint256 start,
        uint256 minEnd,
        uint256 maxEnd
    ) external view {
        if (!exists(pType)) {
            // non-existing template
            revert UnknownTemplate(pType);
        }
        ProposalTemplate memory template = proposalTemplates[pType];
        if (executable != template.executable) {
            // inconsistent executable flag
            revert ExecutableTypeMismatch(executable, template.executable);
        }
        if (minVotes < template.minVotes) {
            // turnout is too small
            revert MinVotesTooSmall(minVotes, template.minVotes);
        }
        if (minVotes > Decimal.unit()) {
            // turnout is bigger than 100%
            revert MinVotesTooLarge(minVotes, Decimal.unit());
        }
        if (minAgreement < template.minAgreement) {
            // quorum is too small
            revert MinAgreementTooSmall(minAgreement, template.minAgreement);
        }
        if (minAgreement > Decimal.unit()) {
            // quorum is bigger than 100%
            revert MinAgreementTooLarge(minAgreement, Decimal.unit());
        }
        if (opinionScales.length != template.opinionScales.length) {
            // wrong opinion scales
            revert OpinionScalesLengthMismatch(opinionScales.length, template.opinionScales.length);
        }
        for (uint256 i = 0; i < opinionScales.length; i++) {
            if (opinionScales[i] != template.opinionScales[i]) {
                revert OpinionScalesMismatch(opinionScales[i], template.opinionScales[i], i);
            }
        }
        if (start < block.timestamp) {
            revert StartIsInThePast();
        }
        if (start > minEnd) {
            revert StartIsAfterMinEnd(start, minEnd);
        }
        if (minEnd > maxEnd) {
            revert MinEndIsAfterMaxEnd(minEnd, maxEnd);
        }

        uint256 minDuration = minEnd - start;
        uint256 maxDuration = maxEnd - start;
        uint256 startDelay_ = start - block.timestamp;
        if (minDuration < template.minVotingDuration) {
            revert MinDurationIsTooShort(minDuration, template.minVotingDuration);
        }
        if (maxDuration > template.maxVotingDuration) {
            revert MaxDurationIsTooLong(maxDuration, template.maxVotingDuration);
        }
        if (startDelay_ < template.minStartDelay) {
            revert StartDelayIsTooSmall(startDelay_, template.minStartDelay);
        }
        if (startDelay_ > template.maxStartDelay) {
            revert StartDelayIsTooLarge(startDelay_, template.maxStartDelay);
        }
        if (template.verifier == address(0)) {
            // template with no additional verifier
            return;
        }
        IProposalVerifier(template.verifier).verifyProposalParams(
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
    function verifyProposalContract(uint256 pType, address propAddr) external view {
        if (!exists(pType)) {
            revert UnknownTemplate(pType);
        }
        ProposalTemplate memory template = proposalTemplates[pType];
        // Skip verification if no verifier is set
        if (template.verifier == address(0)) {
            return;
        }

        IProposalVerifier(template.verifier).verifyProposalContract(pType, propAddr);
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
