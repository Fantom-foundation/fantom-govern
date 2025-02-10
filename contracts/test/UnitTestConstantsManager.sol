// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Decimal} from "../common/Decimal.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev UnitTestConstantsManager is a contract for managing constants for unit tests
contract UnitTestConstantsManager is Ownable {
    // Minimum amount of stake for a validator, i.e., 500000 FTM
    uint256 public minSelfStake;
    // Maximum ratio of delegations a validator can have, say, 15 times of self-stake
    uint256 public maxDelegatedRatio;
    // The commission fee in percentage a validator will get from a delegation, e.g., 15%
    uint256 public validatorCommission;
    // The percentage of fees to burn, e.g., 20%
    uint256 public burntFeeShare;
    // The percentage of fees to transfer to treasury address, e.g., 10%
    uint256 public treasuryFeeShare;
    // The ratio of the reward rate at base rate (no lock), e.g., 30%
    uint256 public unlockedRewardRatio;
    // The minimum duration of a stake/delegation lockup, e.g. 2 weeks
    uint256 public minLockupDuration;
    // The maximum duration of a stake/delegation lockup, e.g. 1 year
    uint256 public maxLockupDuration;
    // the number of epochs that undelegated stake is locked for
    uint256 public withdrawalPeriodEpochs;
    // the number of seconds that undelegated stake is locked for
    uint256 public withdrawalPeriodTime;

    uint256 public baseRewardPerSecond;
    uint256 public offlinePenaltyThresholdBlocksNum;
    uint256 public offlinePenaltyThresholdTime;
    uint256 public targetGasPowerPerSecond;
    uint256 public gasPriceBalancingCounterweight;
    
    error ValueTooLarge();
    error ValueTooSmall();

    constructor() Ownable(msg.sender) {}

    function updateMinSelfStake(uint256 v) external {
        if (v > 1000000000 * Decimal.unit()) {
            revert ValueTooLarge();
        }
        minSelfStake = v;
    }

    function updateMaxDelegatedRatio(uint256 v) external {
        if (v < Decimal.unit()) {
            revert ValueTooSmall();
        }
        if (v > 1000000 * Decimal.unit()) {
            revert ValueTooLarge();
        }
        maxDelegatedRatio = v;
    }

    function updateValidatorCommission(uint256 v) external {
        if (v > Decimal.unit()) {
            revert ValueTooLarge();
        }
        validatorCommission = v;
    }

    function updateBurntFeeShare(uint256 v) external {
        if (v > Decimal.unit()) {
            revert ValueTooLarge();
        }
        burntFeeShare = v;
    }

    function updateTreasuryFeeShare(uint256 v) external {
                if (v > Decimal.unit()) {
            revert ValueTooLarge();
        }
        treasuryFeeShare = v;
    }

    function updateUnlockedRewardRatio(uint256 v) external {
                if (v > Decimal.unit()) {
            revert ValueTooLarge();
        }
        unlockedRewardRatio = v;
    }

    function updateMinLockupDuration(uint256 v) external {
        if (v < 43200) {
            revert ValueTooSmall();
        }
        if (v > 2147483648) {
            revert ValueTooLarge();
        }
    }

    function updateMaxLockupDuration(uint256 v) external {
        if (v < minLockupDuration) {
            revert ValueTooSmall();
        }
        if (v > 2147483648) {
            revert ValueTooLarge();
        }
        maxLockupDuration = v;
    }

    function updateWithdrawalPeriodEpochs(uint256 v) external {
        if (v < 1) {
            revert ValueTooSmall();
        }
        if (v > 100000000) {
            revert ValueTooLarge();
        }
        withdrawalPeriodEpochs = v;
    }

    function updateWithdrawalPeriodTime(uint256 v) external {
        if (v < 3600) {
            revert ValueTooSmall();
        }
        if (v > 2147483648) {
            revert ValueTooLarge();
        }
        withdrawalPeriodTime = v;
    }

    function updateBaseRewardPerSecond(uint256 v) external {
        if (v > 32.967977168935185184 * 1e18) {
            revert ValueTooLarge();
        }
        baseRewardPerSecond = v;
    }

    function updateOfflinePenaltyThresholdTime(uint256 v) external {
        if (v < 60) {
            revert ValueTooSmall();
        }
        offlinePenaltyThresholdTime = v;
    }

    function updateOfflinePenaltyThresholdBlocksNum(uint256 v) external {
        if (v < 10) {
            revert ValueTooSmall();
        }
        offlinePenaltyThresholdBlocksNum = v;
    }

    function updateTargetGasPowerPerSecond(uint256 v) external {
        if (v < 1000) {
            revert ValueTooSmall();
        }
        if (v > 500000000) {
            revert ValueTooLarge();
        }
        targetGasPowerPerSecond = v;
    }

    function updateGasPriceBalancingCounterweight(uint256 v) external {
        if (v < 1) {
            revert ValueTooSmall();
        }
        if (v > 1000000000) {
            revert ValueTooLarge();
        }
        gasPriceBalancingCounterweight = v;
    }
}