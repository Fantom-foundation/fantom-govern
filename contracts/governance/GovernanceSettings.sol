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
    uint256 constant _proposalFee = 100 * 1e18;
    uint256 constant _maxOptions = 10;
    uint256 constant _maxExecutionPeriod = 3 days;

    // @dev maxOptionResistance is the maximum acceptable ratio of veto votes for an option.
    //      It's guaranteed not to win otherwise.
    //      Equal to 40%.
    function maxOptionDesignation() public pure returns (uint256) {
        return 40 * Decimal.unit() / 100;
    }

    // @dev maxOptionResistance is the maximum acceptable ratio of resistance for an option.
    //      It's guaranteed not to win otherwise.
    //      Equal to 40%.
    function maxOptionResistance() public pure returns (uint256) {
        return 40 * Decimal.unit() / 100;
    }

    // @dev proposalFee is the fee for a proposal
    function proposalFee() public pure returns (uint256) {
        return _proposalFee;
    }

    // @dev maxOptions maximum number of options to choose
    function maxOptions() public pure returns (uint256) {
        return _maxOptions;
    }

    // maxExecutionPeriod is maximum time for which proposal is executable after maximum voting end date
    function maxExecutionPeriod() public pure returns (uint256) {
        return _maxExecutionPeriod;
    }
}
