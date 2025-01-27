// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../../ownership/Ownable.sol";
import "../../governance/Governance.sol";

/// @notice Extends any contract with the ability to cancel a proposal
contract Cancelable is Ownable {
    constructor() {
        Ownable.initialize(msg.sender);
    }

    /// @notice Cancel a proposal
    /// @param myID ID of the proposal to cancel
    /// @param govAddress Address of the governance contract
    function cancel(uint256 myID, address govAddress) virtual external onlyOwner {
        Governance gov = Governance(govAddress);
        gov.cancelProposal(myID);
    }
}
