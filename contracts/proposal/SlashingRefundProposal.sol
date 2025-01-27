// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./base/DelegatecallExecutableProposal.sol";
import "./base/Cancelable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice An interface to update slashing penalty ratio
interface SFC {
    function updateSlashingRefundRatio(uint256 validatorID, uint256 ratio) external;

    function isSlashed(uint256 validatorID) external returns(bool);
}

/// @notice A proposal to refund a slashed validator
contract SlashingRefundProposal is DelegatecallExecutableProposal, Cancelable {
    uint256 public validatorID;
    address public sfc;

    constructor(
        uint256 _validatorID,
        string memory _description,
        uint256 _minVotes,
        uint256 _minAgreement,
        uint256 _start,
        uint256 _minEnd,
        uint256 _maxEnd,
        address _sfc,
        address verifier
    ) {
        _name = string(abi.encodePacked("Refund for Slashed Validator #", Strings.toString(_validatorID)));
        _description = _description;
        _options.push(bytes32("0%"));
        _options.push(bytes32("20%"));
        _options.push(bytes32("40%"));
        _options.push(bytes32("60%"));
        _options.push(bytes32("80%"));
        _options.push(bytes32("100%"));
        _minVotes = _minVotes;
        _minAgreement = _minAgreement;
        _opinionScales = [0, 1, 2, 3, 4];
        _start = _start;
        _minEnd = _minEnd;
        _maxEnd = _maxEnd;
        validatorID = _validatorID;
        sfc = _sfc;
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