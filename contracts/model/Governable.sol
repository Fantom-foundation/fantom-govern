pragma solidity ^0.5.0;

/**
 * @dev Governable defines the main interface for all governable items
 */
interface Governable {
    // Gets the total weight of voters
    function getTotalWeight() external view returns (uint256);

    // Gets the voting weight of the specified address (own weight, received delegated weight)
    function getWeight(address addr) external view returns (uint256, uint256);

    // Gets the voting weight which is delegated from the specified address to the specified address
    function getDelegatedWeight(address from, address to) external view returns (uint256);
}
