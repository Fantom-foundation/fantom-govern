import {ethers} from "hardhat";
import {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/signers";

const NonExecutableType = 0n;
const CallType = 1n;
const DelegateCallType = 2n;

const initConsts = async function (defaultAcc: HardhatEthersSigner) {
    const consts = await ethers.deployContract("UnitTestConstantsManager",{from: defaultAcc});
    await consts.initialize();
    await consts.updateMinSelfStake(317500000000000000n, {from: defaultAcc});
    await consts.updateMaxDelegatedRatio(16000000000000000000n, {from: defaultAcc});
    await consts.updateBurntFeeShare(2n, {from: defaultAcc});
    await consts.updateTreasuryFeeShare(10n, {from: defaultAcc});
    await consts.updateUnlockedRewardRatio(30n, {from: defaultAcc});
    await consts.updateMinLockupDuration(1209600n, {from: defaultAcc});
    await consts.updateMaxLockupDuration(31536000n, {from: defaultAcc});
    await consts.updateWithdrawalPeriodEpochs(3n, {from: defaultAcc});
    await consts.updateWithdrawalPeriodTime(604800n, {from: defaultAcc});
    await consts.updateBaseRewardPerSecond(32n, {from: defaultAcc});
    await consts.updateOfflinePenaltyThresholdTime(3600n, {from: defaultAcc});
    await consts.updateOfflinePenaltyThresholdBlocksNum(10n, {from: defaultAcc});
    await consts.updateTargetGasPowerPerSecond(1000n, {from: defaultAcc});
    await consts.updateGasPriceBalancingCounterweight(1n, {from: defaultAcc});
    return consts;
};

export {initConsts, NonExecutableType, CallType, DelegateCallType};