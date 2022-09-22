pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./base/Cancelable.sol";
import "./base/DelegatecallExecutableProposal.sol";

interface SFC {
    function setMaxDelegation(uint256) external;
    function setMinSelfStake(uint256) external;
    function setValidatorCommission(uint256) external;
    function setContractCommission(uint256) external;
    function setUnlockedRewardRatio(uint256) external;
    function setMinLockupDuration(uint256) external;
    function setMaxLockupDuration(uint256) external;
    function setWithdrawalPeriodEpoch(uint256) external;
    function setWithdrawalPeriodTime(uint256) external;
}

/**
 * @dev NetworkParameterProposal proposal
 */
contract NetworkParameterProposal is DelegatecallExecutableProposal, Cancelable {
    Proposal.ExecType _exec;
    SFC public sfc;
    uint8 public functionSignature;
    uint256[] public optionsList;

    constructor(
        string[] memory __strings,
        uint8 __functionSignature,
        bytes32[] memory __options,
        uint256[] memory __params,
        uint256[] memory __optionsList,
        Proposal.ExecType __exec,
        address __sfc,
        address verifier
    ) public {
        _name = __strings[0];
        _description = __strings[1];
        functionSignature = __functionSignature;
        _options = __options;
        _minVotes = __params[0];
        _minAgreement = __params[1];
        _start = __params[2];
        _minEnd = __params[3];
        _maxEnd = __params[4];
        optionsList = __optionsList;
        _opinionScales = [0, 2, 3, 4, 5];
        _exec = __exec;
        sfc = SFC(__sfc);
        // verify the proposal right away to avoid deploying a wrong proposal
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed verification");
        }
    }

    function pType() public view returns (uint256) {
        return 15;
    }

    function executable() public view returns (Proposal.ExecType) {
        return _exec;
    }

    event NetworkParameterUpgradeIsDone(uint256 newValue);

    function execute_delegatecall(address selfAddr, uint256 winnerOptionID)
        external
    {
        NetworkParameterProposal self = NetworkParameterProposal(selfAddr);

        if (self.functionSignature() == 1) {
            self.sfc().setMaxDelegation(self.optionsList(winnerOptionID));
        } else if (self.functionSignature() == 2) {
            self.sfc().setValidatorCommission(self.optionsList(winnerOptionID));
        } else if (self.functionSignature() == 3) {
            self.sfc().setContractCommission(self.optionsList(winnerOptionID));
        } else if (self.functionSignature() == 4) {
            self.sfc().setUnlockedRewardRatio(self.optionsList(winnerOptionID));
        } else if (self.functionSignature() == 5) {
            self.sfc().setMinLockupDuration(self.optionsList(winnerOptionID));
        } else if (self.functionSignature() == 6) {
            self.sfc().setMaxLockupDuration(self.optionsList(winnerOptionID));
        } else if (self.functionSignature() == 7) {
            self.sfc().setWithdrawalPeriodEpoch(self.optionsList(winnerOptionID));
        } else if (self.functionSignature() == 8) {
            self.sfc().setWithdrawalPeriodTime(self.optionsList(winnerOptionID));
        } else {
            self.sfc().setMinSelfStake(self.optionsList(winnerOptionID));
        }

        // self.sfcAddress().call(abi.encodeWithSignature(self.functionSignature(), self.optionsList(winnerOptionID)));
        emit NetworkParameterUpgradeIsDone(self.optionsList(winnerOptionID));
    }
}