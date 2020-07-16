pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Constants.sol";
import "./Governable.sol";
import "./SoftwareUpgradeProposal.sol";
import "../common/ImplementationValidator.sol";


contract GovernanceSettings is Constants {
    uint256 _proposalFee = 1500;
    uint256 _maximumlPossibleResistance = 4000;
    uint256 _maximumlPossibleDesignation = 4000;

    function proposalFee() public view returns(uint256) {
        return _proposalFee;
    }
}
