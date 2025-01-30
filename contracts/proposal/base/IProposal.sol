pragma solidity ^0.5.0;

import "../../governance/Proposal.sol";

/// @notice An abstract proposal
contract IProposal {
    /// @dev Get type of proposal (e.g. plaintext, software upgrade)
    /// If BaseProposal.sol is used, must be overridden
    /// @return Proposal type
    function pType() external view returns (uint256);

    /// @dev Proposal execution type when proposal gets resolved
    /// If BaseProposal.sol is used, must be overridden
    /// @return Proposal execution type
    function executable() external view returns (Proposal.ExecType);

    /// @dev Get min. turnout (ratio)
    /// @return Minimal necessary votes
    function minVotes() external view returns (uint256);

    /// @dev Get min. agreement for options (ratio)
    /// @return Minimal agreement threshold for options
    function minAgreement() external view returns (uint256);

    /// @dev Get scales for opinions
    /// @return Scales for opinions
    function opinionScales() external view returns (uint256[] memory);

    /// @dev Get options to choose from
    /// @return Options to choose from
    function options() external view returns (bytes32[] memory);

    /// @dev Get date when the voting starts
    /// @return Timestamp when the voting starts
    function votingStartTime() external view returns (uint256);

    /// @dev Get date of earliest possible voting end
    /// @return Timestamp of earliest possible voting end
    function votingMinEndTime() external view returns (uint256);

    /// @dev Get date of latest possible voting end
    /// @return Timestamp of latest possible voting end
    function votingMaxEndTime() external view returns (uint256);

    /// @dev execute proposal logic on approval (if executable == call)
    /// @dev Called via call opcode from governance contract
    /// @param optionID The index of the option to execute
    function execute_call(uint256 optionID) external;

    /// @dev execute proposal logic on approval (if executable == delegatecall)
    /// @dev Called via delegatecall opcode from governance contract, hence selfAddress is provided
    /// @param selfAddress The address of the proposal contract
    /// @param optionID The index of the option to execute
    function execute_delegatecall(address selfAddress, uint256 optionID) external;

    /// @dev Get human-readable name
    /// @return Human-readable name
    function name() external view returns (string memory);
    /// @dev Get human-readable description
    /// @return Human-readable description
    function description() external view returns (string memory);

    /// @dev Standard proposal types. The standard may be outdated, actual proposal templates may differ
    enum StdProposalTypes {
        NOT_INIT,
        UNKNOWN_NON_EXECUTABLE,
        UNKNOWN_CALL_EXECUTABLE,
        UNKNOWN_DELEGATECALL_EXECUTABLE
    }
}
