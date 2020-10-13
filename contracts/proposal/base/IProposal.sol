pragma solidity ^0.5.0;

import "../../governance/Proposal.sol";

/**
 * @dev An abstract proposal
 */
contract IProposal {
    // Get type of proposal (e.g. plaintext, software upgrade)
    function pType() external view returns (uint256);
    // Proposal execution type when proposal gets resolved
    function executable() external view returns (Proposal.ExecType);
    // Get min. turnout (ratio)
    function minVotes() external view returns (uint256);
    // Get min. agreement for options (ratio)
    function minAgreement() external view returns (uint256);
    // Get scales for opinions
    function opinionScales() external view returns (uint256[] memory);
    // Get options to choose from
    function options() external view returns (bytes32[] memory);
    // Get date when the voting starts
    function votingStartTime() external view returns (uint256);
    // Get date of earliest possible voting end
    function votingMinEndTime() external view returns (uint256);
    // Get date of latest possible voting end
    function votingMaxEndTime() external view returns (uint256);

    // execute proposal logic on approval (if executable == call)
    // Called via call opcode from governance contract
    function execute_call(uint256 optionID) external;

    // execute proposal logic on approval (if executable == delegatecall)
    // Called via delegatecall opcode from governance contract, hence selfAddress is provided
    function execute_delegatecall(address selfAddress, uint256 optionID) external;

    // Get human-readable name
    function name() external view returns (string memory);
    // Get human-readable description
    function description() external view returns (string memory);

    // Standard proposal types. The standard may be outdated, actual proposal templates may differ
    enum StdProposalTypes {
        NOT_INIT,
        UNKNOWN_NON_EXECUTABLE,
        UNKNOWN_CALL_EXECUTABLE,
        UNKNOWN_DELEGATECALL_EXECUTABLE
    }
}
