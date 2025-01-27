// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./base/Cancelable.sol";
import "./base/DelegatecallExecutableProposal.sol";

/// @notice An interface to update this contract to a destination address
interface Upgradability {
    function upgradeTo(address newImplementation) external;
}

/// @notice A proposal to upgrade a contract to a new implementation
contract SoftwareUpgradeProposal is DelegatecallExecutableProposal, Cancelable {
    address public upgradeableContract;
    address public newImplementation;

    constructor(string memory __name, string memory __description,
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd,
        address __upgradeableContract, address __newImplementation, address verifier) {
        _name = __name;
        _description = __description;
        _options.push(bytes("Level of agreement"));
        _minVotes = __minVotes;
        _minAgreement = __minAgreement;
        _opinionScales = [0, 1, 2, 3, 4];
        _start = __start;
        _minEnd = __minEnd;
        _maxEnd = __maxEnd;
        upgradeableContract = __upgradeableContract;
        newImplementation = __newImplementation;
        // verify the proposal right away to avoid deploying a wrong proposal
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed verification");
        }
    }

    function execute_delegatecall(address selfAddr, uint256) external override {
        SoftwareUpgradeProposal self = SoftwareUpgradeProposal(selfAddr);
        Upgradability(self.upgradeableContract()).upgradeTo(self.newImplementation());
    }
}