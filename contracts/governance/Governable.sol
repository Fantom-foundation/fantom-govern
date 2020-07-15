pragma solidity ^0.5.0;

interface Governable {
    function getTotalWeight() external view returns(uint256);
    function getWeight(address addr) external view returns(uint256, uint256);
    function getDelegatedWeight(address from, address to) external view returns(uint256);
}
