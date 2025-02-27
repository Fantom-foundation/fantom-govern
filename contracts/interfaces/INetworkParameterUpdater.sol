// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface INetworkParametersUpdater {
    function updateMinSelfStake(uint256 v) external;

    function updateMaxDelegatedRatio(uint256 v) external;

    function updateValidatorCommission(uint256 v) external;

    function updateBurntFeeShare(uint256 v) external; // 4

    function updateTreasuryFeeShare(uint256 v) external;

    function updateUnlockedRewardRatio(uint256 v) external;

    function updateMinLockupDuration(uint256 v) external;

    function updateMaxLockupDuration(uint256 v) external; // 8

    function updateWithdrawalPeriodEpochs(uint256 v) external;

    function updateWithdrawalPeriodTime(uint256 v) external;

    function updateBaseRewardPerSecond(uint256 v) external;

    function updateOfflinePenaltyThresholdTime(uint256 v) external; // 12

    function updateOfflinePenaltyThresholdBlocksNum(uint256 v) external;

    function updateTargetGasPowerPerSecond(uint256 v) external;

    function updateGasPriceBalancingCounterweight(uint256 v) external; // 15
}
