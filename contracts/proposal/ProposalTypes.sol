pragma solidity ^0.5.0;

// Standard proposal types (may not match to the actual stored templates in ProposalVerifier)
library StdProposalTypes {
    function unknownNonExecutable() external pure returns (uint256) {
        return 1;
    }
    function unknownExecutable() external pure returns (uint256) {
        return 2;
    }
    function plaintext() external pure returns (uint256) {
        return 3;
    }
    function softwareUpgrade() external pure returns (uint256) {
        return 4;
    }
}
