// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/// @dev The version info of this contract
contract Version {
    // @dev Returns the version of this contract.
    function version() public pure returns (bytes4) {
        // version 00.0.2
        return "0002";
    }
}
