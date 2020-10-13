pragma solidity ^0.5.0;


/**
 * @dev An interface to update this contract to a destination address
 */
interface Upgradability {
    function upgradeTo(address newImplementation) external;
}
