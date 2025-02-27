// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {PlainTextProposal} from "../PlainTextProposal.sol";
import {Governance} from "../../governance/Governance.sol";
import {Proposal} from "../../governance/Proposal.sol";

/// @dev A proposal that can be stores data about NonDelegateCall
/// @dev Used for testing purposes
contract ExecLoggingProposal is PlainTextProposal {
    Proposal.ExecType internal _exec;

    constructor(string memory v1, string memory v2, bytes32[] memory v3,
        uint256 v4, uint256 v5, uint256 v6, uint256 v7, uint256 v8, address v9) PlainTextProposal(v1, v2, v3, v4, v5, v6, v7, v8, v9) {}

    function setOpinionScales(uint256[] memory v) public {
        _opinionScales = v;
    }

    function pType() public override pure returns (uint256) {
        return 15;
    }

    function executable() public override view returns (Proposal.ExecType) {
        return _exec;
    }

    function setExecutable(Proposal.ExecType __exec) public {
        _exec = __exec;
    }

    function cancel(uint256 myID, address govAddress) public override {
        Governance gov = Governance(govAddress);
        gov.cancelProposal(myID);
    }

    uint256 public executedCounter;
    address public executedMsgSender;
    address public executedAs;
    uint256 public executedOption;

    function executeNonDelegateCall(address _executedAs, address _executedMsgSender, uint256 optionID) public {
        executedAs = _executedAs;
        executedMsgSender = _executedMsgSender;
        executedCounter += 1;
        executedOption = optionID;
    }

    function executeDelegateCall(address selfAddr, uint256 optionID) external override {
        ExecLoggingProposal self = ExecLoggingProposal(selfAddr);
        self.executeNonDelegateCall(address(this), msg.sender, optionID);
    }

    function executeCall(uint256 optionID) external override {
        executeNonDelegateCall(address(this), msg.sender, optionID);
    }
}
