pragma solidity ^0.5.0;

import "../common/Decimal.sol";
import "../common/SafeMath.sol";
import "../model/Governable.sol";
import "../proposal/SoftwareUpgradeProposal.sol";
import "./Constants.sol";

/**
 * @dev Various constants for governance governance settings
 */
contract GovernanceSettings is Constants {
    uint256 _proposalFee = 100 * 1e18;
    uint256 _maximumPossibleResistance = 40 * Decimal.unit() / 100; // 40%
    uint256 _maximumPossibleDesignation = 40 * Decimal.unit() / 100; // 40%
    uint256 _maximumOptions = 10;
    uint256 _maximumExecutionDuration = 3 days;

    // @dev proposalFee is the fee for a proposal
    function proposalFee() public view returns (uint256) {
        return _proposalFee;
    }
    
    // @dev maxOptions maximum number of options to choose
    function maxOptions() public view returns (uint256) {
        return _maximumOptions;
    }
    
    // maxExecutionDuration is maximum time for which proposal is executable after maximum voting end date
    function maxExecutionDuration() public view returns (uint256) {
        return _maximumExecutionDuration;
    }
}
