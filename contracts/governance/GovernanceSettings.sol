pragma solidity ^0.5.0;

import "../common/SafeMath.sol";
import "../model/Governable.sol";
import "../proposal/SoftwareUpgradeProposal.sol";
import "./Constants.sol";


/**
 * @dev Various constants for governance governance settings
 */
contract GovernanceSettings is Constants {
    uint256 _proposalFee = 1500;
    uint256 _maximumPossibleResistance = 4000;
    uint256 _maximumPossibleDesignation = 4000;
    uint256 _maximumOptions = 10;
    uint256 _maximumExecutionDuration = 3 days;

    function proposalFee() public view returns (uint256) {
        return _proposalFee;
    }
    function maxOptions() public view returns (uint256) {
        return _maximumOptions;
    }
    // maxExecutionDuration is maximum time for which proposal is executable after maximum voting end date
    function maxExecutionDuration() public view returns (uint256) {
        return _maximumExecutionDuration;
    }
}
