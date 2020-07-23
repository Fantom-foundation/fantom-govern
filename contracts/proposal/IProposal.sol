pragma solidity ^0.5.0;

/**
 * @dev An abstract proposal
 */
contract IProposal {
    // Get type of proposal (e.g. plaintext, software upgrade)
    function pType() external view returns (uint256);
    // True if proposal should get executed on approval
    function executable() external view returns (bool);
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

    // execute proposal logic on approval (if executable)
    // Called via delegatecall from governance contract, hence selfAddress is provided
    function execute(address selfAddress, uint256 optionID) external;

    // Get human-readable name
    function name() external view returns (string memory);
    // Get human-readable description
    function description() external view returns (string memory);

    // Standard proposal types. The standard may be outdated, actual proposal templates may differ
    enum StdProposalTypes {
        NOT_INIT,
        UNKNOWN_NON_EXECUTABLE,
        UNKNOWN_EXECUTABLE,
        PLAIN_TEXT,
        SOFTWARE_UPGRADE
    }
}
