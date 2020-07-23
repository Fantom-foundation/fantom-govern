pragma solidity ^0.5.0;

import "../proposal/PlainTextProposal.sol";

contract ExecLoggingProposal is PlainTextProposal {
    constructor(string memory v1, string memory v2, bytes32[] memory v3,
        uint256 v4, uint256 v5, uint256 v6, uint256 v7, uint256 v8, address v9) PlainTextProposal(v1, v2, v3, v4, v5, v6, v7, v8, v9) public {}

    function setOpinionScales(uint256[] memory v) public {
        _opinionScales = v;
    }

    function pType() public view returns (uint256) {
        return uint256(StdProposalTypes.UNKNOWN_EXECUTABLE);
    }

    function executable() public view returns (bool) {
        return true;
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

    function execute(address selfAddr, uint256 optionID) external {
        ExecLoggingProposal self = ExecLoggingProposal(selfAddr);
        self.executeNonDelegateCall(address(this), msg.sender, optionID);
    }
}
