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

    constructor(
        string memory _name,
        string memory _description,
        uint256 _minVotes,
        uint256 _minAgreement,
        uint256 _start,
        uint256 _minEnd,
        uint256 _maxEnd,
        address _upgradeableContract,
        address _newImplementation,
        address verifier
    ) {
        _name = _name;
        _description = _description;
        _options.push(bytes32("Level of agreement"));
        _minVotes = _minVotes;
        _minAgreement = _minAgreement;
        _opinionScales = [0, 1, 2, 3, 4];
        _start = _start;
        _minEnd = _minEnd;
        _maxEnd = _maxEnd;
        upgradeableContract = _upgradeableContract;
        newImplementation = _newImplementation;
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