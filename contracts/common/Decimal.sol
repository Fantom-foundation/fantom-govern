// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/// @dev Decimal is a library for handling decimal numbers
library Decimal {
    /// @dev unit is a fixed point decimal e.g. 0.123456
    function unit() internal pure returns (uint256) {
        return 1e18;
    }
}
