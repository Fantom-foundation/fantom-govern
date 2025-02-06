// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {DelegatecallExecutableProposal} from "./base/DelegatecallExecutableProposal.sol";
import {Cancelable} from "./base/Cancelable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SFC} from "../adapters/SFCToGovernable.sol";

/// @notice A proposal to refund a slashed validator
contract SlashingRefundProposal is DelegatecallExecutableProposal, Cancelable {
    uint256 public validatorID;
    address public sfc;

    constructor(uint256 __validatorID, string memory __description,
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd,
        address __sfc, address verifier) {
        _name = string(abi.encodePacked("Refund for Slashed Validator #", Strings.toString(__validatorID)));
        _description = __description;
        _options.push(bytes32("0%"));
        _options.push(bytes32("20%"));
        _options.push(bytes32("40%"));
        _options.push(bytes32("60%"));
        _options.push(bytes32("80%"));
        _options.push(bytes32("100%"));
        _minVotes = __minVotes;
        _minAgreement = __minAgreement;
        _opinionScales = [0, 1, 2, 3, 4];
        _start = __start;
        _minEnd = __minEnd;
        _maxEnd = __maxEnd;
        validatorID = __validatorID;
        sfc = __sfc;
        // verify the proposal right away to avoid deploying a wrong proposal
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed verification");
        }
    }

    function pType() public override pure returns (uint256) {
        return 5003;
    }

    function execute_delegatecall(address selfAddr, uint256 optionID) external override {
        SlashingRefundProposal self = SlashingRefundProposal(selfAddr);
        uint256 penaltyRatio = 1e18 * optionID * 20 / 100;
        SFC(self.sfc()).updateSlashingRefundRatio(self.validatorID(), penaltyRatio);
    }

    function decimalsNum(uint256 num) internal pure returns (uint256) {
        uint decimals;
        while (num != 0) {
            decimals++;
            num /= 10;
        }
        return decimals;
    }
}