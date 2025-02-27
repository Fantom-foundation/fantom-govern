// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Cancelable} from "./base/Cancelable.sol";
import {DelegatecallExecutableProposal} from "./base/DelegatecallExecutableProposal.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/// @notice A proposal to upgrade a contract to a new implementation
contract SoftwareUpgradeProposal is DelegatecallExecutableProposal, Cancelable {
    address public upgradeableContract;
    address public newImplementation;
    bytes public data;

    constructor(
        string memory name,
        string memory description,
        uint256 minVotes,
        uint256 minAgreement,
        uint256 start,
        uint256 minEnd,
        uint256 maxEnd,
        address upgradeableContract,
        address newImplementation,
        address verifier,
        bytes memory _data
    ) {
        _name = name;
        _description = description;
        _options.push(bytes32("Level of agreement"));
        _minVotes = minVotes;
        _minAgreement = minAgreement;
        _opinionScales = [0, 1, 2, 3, 4];
        _start = start;
        _minEnd = minEnd;
        _maxEnd = maxEnd;
        upgradeableContract = upgradeableContract;
        newImplementation = newImplementation;
        data = _data;
        // verify the proposal right away to avoid deploying a wrong proposal
        if (verifier != address(0)) {
            verifyProposalParams(verifier);
        }
    }

    function executeDelegateCall(address selfAddr, uint256) external override {
        SoftwareUpgradeProposal self = SoftwareUpgradeProposal(selfAddr);
        ITransparentUpgradeableProxy(
            self.upgradeableContract()
        ).upgradeToAndCall(
            self.newImplementation(),
            self.data()
        );
    }
}