// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../../governance/Governance.sol";

/// @dev Extends any contract with the ability to cancel a proposal
contract Cancelable is Ownable {
    constructor() Ownable(msg.sender) {}

    /// @dev Cancel a proposal
    /// @param myID ID of the proposal to cancel
    /// @param govAddress Address of the governance contract
    function cancel(uint256 myID, address govAddress) external virtual onlyOwner {
        Governance gov = Governance(govAddress);
        gov.cancelProposal(myID);
    }
}
