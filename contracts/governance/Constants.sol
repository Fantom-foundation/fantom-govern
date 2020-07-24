pragma solidity ^0.5.0;

import "../common/SafeMath.sol";
import "../common/Decimal.sol";

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

contract Constants is StatusConstants {
    using SafeMath for uint256;

    function minVotesAbsolute(uint256 totalWeight, uint256 minVotesRatio) public pure returns (uint256) {
        return totalWeight * minVotesRatio / Decimal.unit();
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
