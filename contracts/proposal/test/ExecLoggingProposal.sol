pragma solidity ^0.5.0;

import "../PlainTextProposal.sol";
import "../../governance/Governance.sol";
import "../../governance/Proposal.sol";

contract ExecLoggingProposal is PlainTextProposal {
    Proposal.ExecType _exec;

    constructor(string memory v1, string memory v2, bytes32[] memory v3,
        uint256 v4, uint256 v5, uint256 v6, uint256 v7, uint256 v8, address v9) PlainTextProposal(v1, v2, v3, v4, v5, v6, v7, v8, v9) public {}

    function setOpinionScales(uint256[] memory v) public {
        _opinionScales = v;
    }

    function pType() public view returns (uint256) {
        return 15;
    }

    function executable() public view returns (Proposal.ExecType) {
        return _exec;
    }

    function setExecutable(Proposal.ExecType __exec) public {
        _exec = __exec;
    }

    function cancel(uint256 myID, address govAddress) public {
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

    function execute_delegatecall(address selfAddr, uint256 optionID) external {
        ExecLoggingProposal self = ExecLoggingProposal(selfAddr);
        self.executeNonDelegateCall(address(this), msg.sender, optionID);
    }

    function execute_call(uint256 optionID) external {
        executeNonDelegateCall(address(this), msg.sender, optionID);
    }
}
