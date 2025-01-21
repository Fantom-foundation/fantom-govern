pragma solidity ^0.5.0;

import "../../ownership/Ownable.sol";
import "../../governance/Governance.sol";

/// @dev Extends any contract with the ability to cancel a proposal
contract Cancelable is Ownable {
    constructor() public {
        Ownable.initialize(msg.sender);
    }

    /// @dev Cancel a proposal
    /// @param myID ID of the proposal to cancel
    /// @param govAddress Address of the governance contract
    function cancel(uint256 myID, address govAddress) external onlyOwner {
        Governance gov = Governance(govAddress);
        gov.cancelProposal(myID);
    }
}
