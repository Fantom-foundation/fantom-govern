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
