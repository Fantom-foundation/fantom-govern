pragma solidity ^0.5.0;

import "../common/SafeMath.sol";
import "../common/GetCode.sol";
import "../common/Decimal.sol";
import "../proposal/IProposal.sol";
import "../proposal/IProposalVerifier.sol";
import "../ownership/Ownable.sol";

/**
 * @dev A storage of current proposal templates. Any new proposal will be verified against the stored template of its type. 
 *      Verification checks for proposal code and parameters.
 *      Supposed to be owned by the governance contract
 */
contract ProposalTemplates is IProposalVerifier, Ownable {
    using GetCode for address;

    // Stored data for a proposal template
    struct ProposalTemplate {
        string name;
        address exampleAddress; // used as a code template
        bytes32 codeHash; // sha3 hash of code
        bool executable; // true if proposal should get executed on approval
        uint256 minVotes; // min. quorum (ratio)
        uint256 minVotingDuration; // minimum duration of the voting
        uint256 maxVotingDuration; // maximum duration of the voting
        uint256 minStartDelay; // minimum delay of the voting (i.e. must start with a delay)
        uint256 maxStartDelay; // maximum delay of the voting (i.e. must start sooner)
    }

    // templates library
    mapping(uint256 => ProposalTemplate) proposalTemplates; // proposal type -> ProposalTemplate

    // templateExists returns true if proposal template is present
    function templateExists(uint256 pType) public view returns (bool) {
        return bytes(proposalTemplates[pType].name).length != 0;
    }

    // addTemplate adds a template into the library
    // template must have unique type
    function addTemplate(uint256 pType, string calldata name, address exampleAddress, bool executable, uint256 minVotes, uint256 minVotingDuration, uint256 maxVotingDuration, uint256 minStartDelay, uint256 maxStartDelay) external onlyOwner {
        ProposalTemplate storage template = proposalTemplates[pType];
        // empty name is a marker of non-existing template
        require(bytes(name).length != 0, "empty name");
        require(!templateExists(pType), "template already exists");
        template.name = name;
        template.exampleAddress = exampleAddress;
        if (exampleAddress != address(0)) {
            // empty exampleAddress means "no constrains on code"
            template.codeHash = exampleAddress.codeHash();
        }
        template.executable = executable;
        template.minVotes = minVotes;
        template.minVotingDuration = minVotingDuration;
        template.maxVotingDuration = maxVotingDuration;
        template.minStartDelay = minStartDelay;
        template.maxStartDelay = maxStartDelay;
    }

    // eraseTemplate removes the template of specified type from the library
    function eraseTemplate(uint256 pType) external onlyOwner {
        require(templateExists(pType), "template doesn't exist");
        delete (proposalTemplates[pType]);
    }

    // verifyProposalParams checks proposal code and parameters
    function verifyProposalParams(uint256 pType, bool exec, uint256 minVotes, uint256 start, uint256 minEnd, uint256 maxEnd) external view returns (bool) {
        if (start < block.timestamp) {
            // start in the past
            return false;
        }
        if (minEnd > maxEnd) {
            // inconsistent data
            return false;
        }
        if (start > minEnd) {
            // inconsistent data
            return false;
        }
        uint256 minDuration = minEnd - start;
        uint256 maxDuration = maxEnd - start;
        uint256 startDelay_ = start - block.timestamp;

        if (!templateExists(pType)) {
            // non-existing template
            return false;
        }
        ProposalTemplate memory template = proposalTemplates[pType];
        if (exec != template.executable) {
            // inconsistent executable flag
            return false;
        }
        if (minVotes < template.minVotes) {
            // quorum is too small
            return false;
        }
        if (minVotes > Decimal.unit()) {
            // quorum is bigger than 100%
            return false;
        }
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
        return true;
    }

    // verifyProposalCode verifies proposal code from the specified type and address
    function verifyProposalCode(uint256 pType, address propAddr) external view returns (bool) {
        if (!templateExists(pType)) {
            // non-existing template
            return false;
        }
        ProposalTemplate memory template = proposalTemplates[pType];
        if (template.codeHash == bytes32(0)) {
            // template with no requirements to code
            return true;
        }
        return template.codeHash == propAddr.codeHash();
    }
}
