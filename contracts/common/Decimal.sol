pragma solidity ^0.5.0;

library Decimal {
    // unit is used for decimals, e.g. 0.123456
    function unit() external pure returns (uint256) {
        return 1e18;
    }
}
