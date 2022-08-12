/**
* @notice UnitTestMockSFC contract strips SFC contract of all logical functionality and leaves only 
* governable functions, corresponding variables, and getter functions for calculation purposes to 
* recreate the impact of governance contracts applied to SFC.
 */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../ownership/Ownable.sol";
import "../common/Decimal.sol";

interface IGovernance {
    function activeProposals() external view returns (uint256);
}

contract UnitTestMockSFC is Ownable {
    IGovernance internal governance;
    using SafeMath for uint256;

    uint256 public minStakeAmnt;
    uint256 public maxDelegation;
    uint256 public validatorCommissionFee;
    uint256 public contractCommissionFee;
    uint256 public unlockedReward;
    uint256 public minLockup;
    uint256 public maxLockup;
    uint256 public withdrawalPeriodEpochValue;
    uint256 public withdrawalPeriodTimeValue;

    event UpdatedMinSelfStake(uint256 minSelfStake);
    event UpdatedMaxDelegationRatio(uint256 maxDelegationRatio);
    event UpdatedValidatorCommission(uint256 validatorCommission);
    event UpdatedContractCommission(uint256 contractCommission);
    event UpdatedUnlockedRewardRatio(uint256 unlockedRewardRatio);
    event UpdatedMinLockupDuration(uint256 minLockupDuration);
    event UpdatedMaxLockupDuration(uint256 maxLockupDuration);
    event UpdatedWithdrawalPeriodEpoch(uint256 Value);
    event UpdatedWithdrawalPeriodTime(uint256 withValuedrawalPeriodTime);

    /*
    GovernanceToSFC
    */

    function getGovernance() public view returns (address) {
        return address(governance);
    }

    function activeProposals() public view returns (uint256) {
        return governance.activeProposals();
    }

    modifier noActiveProposals() {
        require(activeProposals() == 0, "GovernanceToSFC: There are active proposals.");
        _;
    }

    /*
    Getters
    */

    function maxDelegatedRatio() public view returns (uint256) {
        return maxDelegation * Decimal.unit();
    }

    /**
     * @dev The commission fee in percentage a validator will get from a delegation, e.g., 15%
     */
    function validatorCommission() public view returns (uint256) {
        return (validatorCommissionFee * Decimal.unit()) / 100;
    }

    /**
     * @dev The commission fee in percentage a validator will get from a contract, e.g., 30%
     */
    function contractCommission() public view returns (uint256) {
        return (contractCommissionFee * Decimal.unit()) / 100;
    }

    /**
     * @dev The ratio of the reward rate at base rate (no lock), e.g., 30%
     */
    function unlockedRewardRatio() public view returns (uint256) {
        return (unlockedReward * Decimal.unit()) / 100;
    }

    /**
     * @dev The minimum duration of a stake/delegation lockup, e.g. 2 weeks
     */
    function minLockupDuration() public view returns (uint256) {
        return minLockup * 14;
    }

    /**
     * @dev The maximum duration of a stake/delegation lockup, e.g. 1 year
     */
    function maxLockupDuration() public view returns (uint256) {
        return maxLockup * 365;
    }

    /**
     * @dev the number of epochs that stake is locked
     */
    function withdrawalPeriodEpochs() public view returns (uint256) {
        return withdrawalPeriodEpochValue;
    }

    function withdrawalPeriodTime() public view returns (uint256) {
        return withdrawalPeriodTimeValue;
    }

    /*
    Constructor
    */

    function initialize(
        address _owner,
        address _governance
    ) external initializer {
        Ownable.initialize(_owner);
        governance = IGovernance(_governance);
    }

    /*
    Governable functions
    */

    function _onlyGovernance(address _sender) internal {
        require((_sender == getGovernance() || _sender == owner()), "SFC: this function is controlled by the owner and governance contract");
    }

    function setMaxDelegation(uint256 _maxDelegationRatio) external {
        _onlyGovernance(msg.sender);
        _updateMaxDelegation(_maxDelegationRatio);
    }

    function _updateMaxDelegation(uint256 _maxDelegation) internal {
        maxDelegation = _maxDelegation;
        emit UpdatedMaxDelegationRatio(_maxDelegation);
    }

    function setMinSelfStake(uint256 _minSelfStake) external {
        _onlyGovernance(msg.sender);
        _updateMinSelfStake(_minSelfStake);
    }

    function _updateMinSelfStake(uint256 _minSelfStake) internal {
        minStakeAmnt = _minSelfStake;
        emit UpdatedMinSelfStake(_minSelfStake);
    }

    function setValidatorCommission(uint256 _validatorCommission) external {
        _onlyGovernance(msg.sender);
        _updateValidatorCommission(_validatorCommission);
    }

    function _updateValidatorCommission(uint256 _validatorCommission) internal {
        validatorCommissionFee = _validatorCommission;
        emit UpdatedValidatorCommission(_validatorCommission);
    }

    function setContractCommission(uint256 _contractCommission) external {
        _onlyGovernance(msg.sender);
        _updateContractCommission(_contractCommission);
    }

    function _updateContractCommission(uint256 _contractCommission) internal {
        contractCommissionFee = _contractCommission;
        emit UpdatedContractCommission(_contractCommission);
    }

    function setUnlockedRewardRatio(uint256 _unlockedReward) external {
        _onlyGovernance(msg.sender);
        _updateUnlockedRewardRatio(_unlockedReward);
    }

    function _updateUnlockedRewardRatio(uint256 _unlockedReward) internal {
        unlockedReward = _unlockedReward;
        emit UpdatedUnlockedRewardRatio(_unlockedReward);
    }

    function setMinLockupDuration(uint256 _minLockupDuration) external {
        _onlyGovernance(msg.sender);
         _updateMinLockupDuration(_minLockupDuration);
    }

    function _updateMinLockupDuration(uint256 _minLockupDuration) internal {
        minLockup = _minLockupDuration;
        emit UpdatedMinLockupDuration(_minLockupDuration);
    }

    function setMaxLockupDuration(uint256 _maxLockupDuration) external {
        _onlyGovernance(msg.sender);
        _updateMaxLockupDuration(_maxLockupDuration);
    }

    function _updateMaxLockupDuration(uint256 _maxLockupDuration) internal {
        maxLockup = _maxLockupDuration;
        emit UpdatedMaxLockupDuration(_maxLockupDuration);
    }

    function setWithdrawalPeriodEpoch(uint256 _withdrawalPeriodEpochs) external {
        _onlyGovernance(msg.sender);
        _updateWithdrawalPeriodEpoch(_withdrawalPeriodEpochs);
    }

    function _updateWithdrawalPeriodEpoch(uint256 _withdrawalPeriodEpochs) internal {
        withdrawalPeriodEpochValue = _withdrawalPeriodEpochs;
        emit UpdatedWithdrawalPeriodEpoch(_withdrawalPeriodEpochs);
    }

    function setWithdrawalPeriodTime(uint256 _withdrawalPeriodTime) external {
        _onlyGovernance(msg.sender);
        _updateWithdrawalPeriodTime(_withdrawalPeriodTime);
    }

    function _updateWithdrawalPeriodTime(uint256 _withdrawalPeriodTime) internal {
        withdrawalPeriodTimeValue = _withdrawalPeriodTime;
        emit UpdatedWithdrawalPeriodTime(_withdrawalPeriodTime);
    }
}