pragma solidity ^0.5.0;

/**
 * @dev An interface for Proposal factory
 */ 
interface IProposalFactory {
    function newPlainTextProposal(bytes32 title, bytes32 desc, bytes32[] calldata options) external;
    function newSoftwareUpgradeProposal(address newContractAddr) external;
    function canVoteForProposal(address prop) external view returns(bool);
    function setProposalIsConsidered(address prop) external;
}
