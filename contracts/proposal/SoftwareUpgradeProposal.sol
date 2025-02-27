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
        string memory __name,
        string memory __description,
        uint256 __minVotes,
        uint256 __minAgreement, uint256 __start,
        uint256 __minEnd,
        uint256 __maxEnd,
        address __upgradeableContract,
        address __newImplementation,
        address verifier,
        bytes memory _data
    ) {
        _name = __name;
        _description = __description;
        _options.push(bytes32("Level of agreement"));
        _minVotes = __minVotes;
        _minAgreement = __minAgreement;
        _opinionScales = [0, 1, 2, 3, 4];
        _start = __start;
        _minEnd = __minEnd;
        _maxEnd = __maxEnd;
        upgradeableContract = __upgradeableContract;
        newImplementation = __newImplementation;
        data = _data;
        // verify the proposal right away to avoid deploying a wrong proposal
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed verification");
        }
    }

    function execute_delegatecall(address selfAddr, uint256) external override {
        SoftwareUpgradeProposal self = SoftwareUpgradeProposal(selfAddr);
        ITransparentUpgradeableProxy(
            self.upgradeableContract()
        ).upgradeToAndCall(
            self.newImplementation(),
            self.data()
        );
    }
}