pragma solidity ^0.5.0;

/**
 * @dev Governable defines the main interface for all governable items
 */
interface Governable {
    // Gets the total votes of a proposal type
    function getTotalVotes(uint256 propType) external view returns(uint256);
    
    // Gets the voting power of the specified address for a proposal type
    function getVotingPower(address addr, uint256 propType) external view returns(uint256, uint256, uint256);
    
    // Gets address of delegated votes to the specified address
    function delegatedVotesTo(address addr) external view returns(address);
}
