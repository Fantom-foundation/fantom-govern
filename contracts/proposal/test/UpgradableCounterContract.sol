// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// @dev UpgradableContract serves as a mock for testing SoftwareUpgradeProposal
contract UpgradableCounterContract is UUPSUpgradeable, OwnableUpgradeable {
    function initialize(address govAddr) public initializer {
        __Ownable_init(govAddr);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
