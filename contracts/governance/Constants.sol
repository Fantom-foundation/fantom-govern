pragma solidity ^0.5.0;

import "../common/SafeMath.sol";

contract StatusConstants {
    enum Status {
        ACTIVE,
        FROZEN,
        VOTING,
        ACCEPTED,
        FAILED,
        IMPLEMENTED
    }

    // bit map
    uint256 constant BIT_IS_ACTIVE = 0;
    uint256 constant BIT_IS_FROSEN = 1;
    uint256 constant BIT_IS_VOTING = 2;
    uint256 constant BIT_IS_ACCEPTED = 3;
    uint256 constant BIT_IS_FAILED = 4;
    uint256 constant BIT_IS_IMPLEMENTED = 5;

    // tasks
    uint256 constant TASK_VOTING = 2;



    // statuses
    uint256 constant ACTIVE = 1;
    uint256 STATUS_VOTING = setStatusVoting(ACTIVE); // immutable
    uint256 STATUS_VOTING_FAILED = failStatus(STATUS_VOTING); // immutable

    function makeStatusActive(uint256 status) public pure returns (uint256) {
        status |= 1 << BIT_IS_ACTIVE;
        return status;
    }

    function failStatus(uint256 status) public pure returns (uint256) {
        status &= ~(1 << BIT_IS_ACTIVE);
        status &= ~(1 << BIT_IS_ACCEPTED);
        status &= ~(1 << BIT_IS_IMPLEMENTED);
        return status;
    }

    function setStatusVoting(uint256 status) public pure returns (uint256) {
        status |= 1 << BIT_IS_VOTING;
        return status;
    }

    function setStatusAccepted(uint256 status) public pure returns (uint256) {
        status |= 1 << BIT_IS_ACCEPTED;
        return status;
    }

    function statusActive(uint256 status) internal view returns (bool) {
        return (status >> BIT_IS_ACTIVE) & 1 == 1;
    }

    function statusInactive(uint256 status) internal view returns (bool) {
        return (status >> BIT_IS_ACTIVE) & 1 == 0;
    }

    function statusVoting(uint256 status) internal view returns (bool) {
        return status == STATUS_VOTING;
    }

    function statusVotingFailed(uint256 status) internal view returns (bool) {
        return status == STATUS_VOTING_FAILED;
    }
}

contract CommonConstants {
    using SafeMath for uint256;

}

contract Constants is StatusConstants {
    using SafeMath for uint256;

    enum ProposalType {
        SOFTWARE_UPGRADE /* software upgrade type */,
        PLAIN_TEXT /* plain text */,
        IMMEDIATE_ACTION /* immediate action */,
        EXECUTABLE /* executable */
    }


    // types
    // uint256 constant TYPE_SOFTWARE_UPGRADE = 0x1; // software upgrade type
    // uint256 constant TYPE_PLAIN_TEXT = 0x2; // plane text type
    // uint256 constant TYPE_IMMEDIATE_ACTION = 0x3; // immediate action type
    uint8 constant TYPE_EXECUTABLE = 0x4;

    // temprorary constant
    uint256 constant CANCEL_VOTE_FEE = 123;
    uint256 constant CANCEL_DELEGATION_FEE = 123;

    // temprorary timestamp constants
    uint256 constant VOTING_PERIOD = 1 weeks;

    function typeExecutable() public pure returns (uint8) {
        return TYPE_EXECUTABLE;
    }

    function cancelVoteFee() public pure returns (uint256) {
        return CANCEL_VOTE_FEE;
    }

    function cancelDelegationFee() public pure returns (uint256) {
        return CANCEL_DELEGATION_FEE;
    }

    function votingPeriod() public pure returns (uint256) {
        return VOTING_PERIOD;
    }

    function minVotesRequired(uint256 totalVotersNum, uint256 proposalType) public view returns (uint256) {
        // default (temprorary?) response is that 2/3 of a voters should vote fore a quorum
        return totalVotersNum * 2 / 3;
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

}
