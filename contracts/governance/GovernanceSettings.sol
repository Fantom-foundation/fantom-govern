pragma solidity ^0.5.0;

import "../common/ImplementationValidator.sol";
import "../common/SafeMath.sol";
import "../model/Governable.sol";
import "../proposal/SoftwareUpgradeProposal.sol";
import "./Constants.sol";


/**
 * @dev Various constants for governance governance settings
 */
contract GovernanceSettings is Constants {
    uint256 _proposalFee = 1500;
    uint256 _minimumVotesRequiredNum = 67;
    uint256 _minimumVotesRequiredDenum = 100;
    uint256 _maximumlPossibleResistance = 4000;
    uint256 _maximumlPossibleDesignation = 4000;

    function proposalFee() public view returns(uint256) {
        return _proposalFee;
    }

    function minimumVotesRequired(uint256 totalVotersNum) public view returns(uint256) {
        return totalVotersNum * _minimumVotesRequiredNum / _minimumVotesRequiredDenum;
    }
}
