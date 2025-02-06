// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/// @notice StatusConstants.sol defines status of governance proposals.
contract StatusConstants {
    enum Status {
        INITIAL,
        RESOLVED,
        FAILED
    }

    // bit map
    uint256 constant public STATUS_INITIAL = 0;
    uint256 constant public STATUS_RESOLVED = 1;
    uint256 constant public STATUS_FAILED = 1 << 1;
    uint256 constant public STATUS_CANCELED = 1 << 2;
    uint256 constant public STATUS_EXECUTION_EXPIRED = 1 << 3;

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