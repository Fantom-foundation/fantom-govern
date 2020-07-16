pragma solidity ^0.5.0;

/**
 * @dev The version info of this contract
 */
contract Version {
	/**
     * @dev Returns the version of this contract.
     */
    function version() public pure returns (bytes4) {
        return "0001"; // version 00.0.1
    }
}
