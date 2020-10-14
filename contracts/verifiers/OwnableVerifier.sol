pragma solidity ^0.5.0;

import "../ownership/Ownable.sol";
import "./IProposalVerifier.sol";
import "../governance/Governance.sol";


contract OwnableVerifier is IProposalVerifier, Ownable {
    constructor() public {
        Ownable.initialize(msg.sender);
    }

    // verifyProposalParams checks proposal parameters
    function verifyProposalParams(uint256, Proposal.ExecType, uint256, uint256, uint256[] calldata, uint256, uint256, uint256) external view returns (bool) {
        return true;
    }

    // verifyProposalContract verifies proposal creator
    function verifyProposalContract(uint256, address) external view returns (bool) {
        return tx.origin == owner();
    }
}
