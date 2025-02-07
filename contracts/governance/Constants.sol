// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Decimal} from "../common/Decimal.sol";

/// @notice StatusConstants defines status of governance proposals.
contract StatusConstants {
    enum Status {
        INITIAL,
        RESOLVED,
        FAILED
    }

    // bit map
    uint256 constant STATUS_INITIAL = 0;
    uint256 constant STATUS_RESOLVED = 1;
    uint256 constant STATUS_FAILED = 1 << 1;
    uint256 constant STATUS_CANCELED = 1 << 2;
    uint256 constant STATUS_EXECUTION_EXPIRED = 1 << 3;

    function statusInitial() internal pure returns (uint256) {
        return STATUS_INITIAL;
    }

    function statusExecutionExpired() internal pure returns (uint256) {
        return STATUS_EXECUTION_EXPIRED;
    }

    function statusFailed() internal pure returns (uint256) {
        return STATUS_FAILED;
    }

    function statusCanceled() internal pure returns (uint256) {
        return STATUS_CANCELED;
    }

    function statusResolved() internal pure returns (uint256) {
        return STATUS_RESOLVED;
    }

    function isInitialStatus(uint256 status) internal pure returns (bool) {
        return status == STATUS_INITIAL;
    }

    // task assignments
    uint256 constant TASK_VOTING = 1;
}

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
