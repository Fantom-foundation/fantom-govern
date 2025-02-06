// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Decimal} from "../common/Decimal.sol";
import {StatusConstants} from "./StatusConstants.sol";

/// @dev Constants is a contract for managing constants
contract Constants is StatusConstants {
    /// @notice calculates the minimum number of votes required for a proposal
    /// @param totalWeight The total weight of the voters
    /// @param minVotesRatio The minimum ratio of votes required
    /// @return The minimum number of votes required
    function minVotesAbsolute(uint256 totalWeight, uint256 minVotesRatio) public pure returns (uint256) {
        return totalWeight * minVotesRatio / Decimal.unit();
    }

    /// @notice converts bytes32 to string
    /// @param _bytes32 The bytes32 to convert
    /// @return The converted string
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
