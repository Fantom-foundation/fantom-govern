// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../model/Governable.sol";

/// @dev UnitTestGovernable is a contract for managing stakes and for unit tests
contract UnitTestGovernable is Governable {
    mapping(address => mapping(address => uint256)) public delegations; // from, to -> amount
    mapping(address => uint256) public rcvDelegations;
    uint256 public totalStake;

    function stake(address to, uint256 amount) external {
        delegations[msg.sender][to] += amount;
        rcvDelegations[to] += amount;
        totalStake += amount;
    }

    function unstake(address to, uint256 amount) external {
        require(delegations[msg.sender][to] >= amount, "not enough stake");
        delegations[msg.sender][to] -= amount;
        rcvDelegations[to] -= amount;
        totalStake -= amount;
    }

    function getTotalWeight() external view returns (uint256) {
        return totalStake;
    }

    function getReceivedWeight(address addr) external view returns (uint256) {
        return rcvDelegations[addr];
    }

    function getWeight(address from, address to) external view returns (uint256) {
        return delegations[from][to];
    }
}
