pragma solidity ^0.5.0;

import "../governance/Governance.sol";

contract UnitTestGovernance is Governance {
    // reduce proposal fee in tests
    function proposalFee() public pure returns (uint256) {
        return proposalBurntFee() + taskHandlingReward() + taskErasingReward();
    }
    function proposalBurntFee() public pure returns (uint256) {
        return 0.05 * 1e18;
    }
    function taskHandlingReward() public pure returns (uint256) {
        return 0.04 * 1e18;
    }
    function taskErasingReward() public pure returns (uint256) {
        return 0.01 * 1e18;
    }
}
