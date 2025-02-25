// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/// @notice An interface to upgrade a contract using SoftwareUpgradeProposal
interface IUpgradeable {
    function upgradeTo(address newImplementation) external;
}
