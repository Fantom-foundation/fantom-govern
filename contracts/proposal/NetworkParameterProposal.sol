// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Cancelable} from "./base/Cancelable.sol";
import {DelegatecallExecutableProposal} from "./base/DelegatecallExecutableProposal.sol";
import {Proposal} from "../governance/Proposal.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface ConstsI {
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

/// @notice A proposal to update network parameters
contract NetworkParameterProposal is DelegatecallExecutableProposal, Cancelable {
    Proposal.ExecType internal _exec;
    ConstsI public consts;
    uint8 public methodID;
    uint256[] public getOptionVal;

    constructor(
        string memory __description,
        uint8 __methodID,
        uint256[] memory __optionsVals,
        address __consts,
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd,
        address verifier
    ) {
        require(__methodID >= 1 && __methodID <= 15, "wrong methodID");
        if (__methodID == 1) {
            _name = "Update minimum self-stake";
            _options = uintsToStrs(__optionsVals, 1e18, " FTM");
        } else if (__methodID == 2) {
            _name = "Update maximum delegated stake ratio";
            _options = uintsToStrs(__optionsVals, 1e16, " %");
        } else if (__methodID == 3) {
            _name = "Update validator rewards commission";
            _options = uintsToStrs(__optionsVals, 1e16, " %");
        } else if (__methodID == 4) {
            _name = "Update burnt fee share";
            _options = uintsToStrs(__optionsVals, 1e16, " %");
        } else if (__methodID == 5) {
            _name = "Update treasury fee share";
            _options = uintsToStrs(__optionsVals, 1e16, " %");
        } else if (__methodID == 6) {
            _name = "Update unlocked reward ratio";
            _options = uintsToStrs(__optionsVals, 1e16, " %");
        } else if (__methodID == 7) {
            _name = "Update minimum lockup duration";
            _options = uintsToStrs(__optionsVals, 1440 minutes, " days");
        } else if (__methodID == 8) {
            _name = "Update maximum lockup duration";
            _options = uintsToStrs(__optionsVals, 1440 minutes, " days");
        } else if (__methodID == 9) {
            _name = "Update number epochs of withdrawal period";
            _options = uintsToStrs(__optionsVals, 1, "");
        } else if (__methodID == 10) {
            _name = "Update withdrawal period";
            _options = uintsToStrs(__optionsVals, 60 minutes, " hours");
        } else if (__methodID == 11) {
            _name = "Update base reward per second";
            _options = uintsToStrs(__optionsVals, 1e18, " FTM");
        } else if (__methodID == 12) {
            _name = "Update time threshold for offline penalty";
            _options = uintsToStrs(__optionsVals, 60 minutes, " hours");
        } else if (__methodID == 13) {
            _name = "Update blocks threshold for offline penalty";
            _options = uintsToStrs(__optionsVals, 1, "");
        } else if (__methodID == 14) {
            _name = "Update target gas power second";
            _options = uintsToStrs(__optionsVals, 1e6, " M");
        } else {
            _name = "Update gas price balancing period";
            _options = uintsToStrs(__optionsVals, 1 minutes, " minutes");
        }
        _description = __description;
        methodID = __methodID;
        _minVotes = __minVotes;
        _minAgreement = __minAgreement;
        _start = __start;
        _minEnd = __minEnd;
        _maxEnd = __maxEnd;
        getOptionVal = __optionsVals;
        _opinionScales = [0, 1, 2, 3, 4];
        consts = ConstsI(__consts);
        // verify the proposal right away to avoid deploying a wrong proposal
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed verification");
        }
    }

    function pType() public override pure returns (uint256) {
        return 6003;
    }

    function optionVals() external view returns (uint256[] memory) {
        return getOptionVal;
    }

    event NetworkParameterUpgradeIsDone(uint256 newValue);

    /// @dev Execute the proposal
    /// @dev Depending on the methodID, the corresponding network parameter will be updated
    /// @param selfAddr The address of the proposal
    /// @param winnerOptionID The winning option ID
    function executeDelegateCall(address selfAddr, uint256 winnerOptionID) external override {
        NetworkParameterProposal self = NetworkParameterProposal(selfAddr);
        uint256 __methodID = self.methodID();

        if (__methodID == 1) {
            self.consts().updateMinSelfStake(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 2) {
            self.consts().updateMaxDelegatedRatio(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 3) {
            self.consts().updateValidatorCommission(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 4) {
            self.consts().updateBurntFeeShare(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 5) {
            self.consts().updateTreasuryFeeShare(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 6) {
            self.consts().updateUnlockedRewardRatio(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 7) {
            self.consts().updateMinLockupDuration(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 8) {
            self.consts().updateMaxLockupDuration(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 9) {
            self.consts().updateWithdrawalPeriodEpochs(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 10) {
            self.consts().updateWithdrawalPeriodTime(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 11) {
            self.consts().updateBaseRewardPerSecond(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 12) {
            self.consts().updateOfflinePenaltyThresholdTime(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 13) {
            self.consts().updateOfflinePenaltyThresholdBlocksNum(self.getOptionVal(winnerOptionID));
        } else if (__methodID == 14) {
            self.consts().updateTargetGasPowerPerSecond(self.getOptionVal(winnerOptionID));
        } else {
            self.consts().updateGasPriceBalancingCounterweight(self.getOptionVal(winnerOptionID));
        }

        emit NetworkParameterUpgradeIsDone(self.getOptionVal(winnerOptionID));
    }

    function decimalsNum(uint256 num) internal pure returns (uint256) {
        uint256 decimals;
        while (num != 0) {
            decimals++;
            num /= 10;
        }
        return decimals;
    }

    /// @dev Convert a decimal to a string
    /// @param integer The integer part of the decimal
    /// @param fractional The fractional part of the decimal
    /// @return The converted string
    function decimalToStr(uint256 integer, uint256 fractional) internal pure returns (string memory) {
        bytes memory intStr = bytes(Strings.toString(integer));
        bytes memory fraStr = bytes(Strings.toString(fractional));
        // replace leading 1 with .
        fraStr[0] = bytes1(uint8(46));
        return string(abi.encodePacked(intStr, fraStr));
    }

    /// @dev Unpack a decimal number
    /// @param num The number to be unpacked
    /// @param unit The unit of the number
    function unpackDecimal(uint256 num, uint256 unit) internal pure returns (uint256 integer, uint256 fractional) {
        assert(unit <= 1e18);
        fractional = (num % unit) * 1e18 / unit;
        return (num / unit, trimFractional(1e18 + fractional));
    }

    /// @dev Trim the fractional part of a decimal
    /// @param fractional The decimal to be trimmed
    /// @return The trimmed decimal
    function trimFractional(uint256 fractional) internal pure returns (uint256) {
        if (fractional == 0) {
            return 0;
        }
        while (fractional % 10 == 0) {
            fractional /= 10;
        }
        return fractional;
    }

    /// @dev Convert an array of uint256 to an array of strings
    /// @param vals The array of uint256 to be converted
    /// @param unit The unit of the numbers
    /// @param symbol The symbol of the numbers
    function uintsToStrs(uint256[] memory vals, uint256 unit, string memory symbol) internal pure returns (bytes32[] memory) {
        bytes32[] memory res = new bytes32[](vals.length);
        for (uint256 i = 0; i < vals.length; i++) {
            (uint256 integer, uint256 fractional) = unpackDecimal(vals[i], unit);
            if (fractional == 1) {
                res[i] = strToB32(string(abi.encodePacked(Strings.toString(integer), symbol)));
            } else {
                res[i] = strToB32(string(abi.encodePacked(decimalToStr(integer, fractional), symbol)));
            }
        }
        return res;
    }


    /// @dev Convert a string to a bytes32
    /// @param str The string to be converted
    /// @return result The converted bytes32
    function strToB32(string memory str) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(str);
        require(tempEmptyStringTest.length <= 32, "string is too long");
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(tempEmptyStringTest, 32))
        }
    }
}