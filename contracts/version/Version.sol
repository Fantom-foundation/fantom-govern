// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/// @notice The version info of the Governance contract
contract Version {
    // @notice Returns the version.
    function version() public pure returns (bytes4) {
        return 0x00000002; // version 0.0.0.2
    }
}
