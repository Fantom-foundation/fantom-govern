pragma solidity ^0.5.0;

import "../governance/Governance.sol";

contract UnitTestGovernance is Governance {
    // reduce proposal fee in tests
    function proposalFee() public pure returns (uint256) {
        return 1e18;
    }
}
