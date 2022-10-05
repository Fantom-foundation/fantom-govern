pragma solidity ^0.5.0;

import "./base/DelegatecallExecutableProposal.sol";
import "./base/Cancelable.sol";

/**
 * @dev An interface to update slashing penalty ratio
 */
interface SFC {
    function updateSlashingRefundRatio(uint256 validatorID, uint256 ratio) external;

    function isSlashed(uint256 validatorID) external returns(bool);
}

contract SlashingRefundProposal is DelegatecallExecutableProposal, Cancelable {
    uint256 public validatorID;
    address public sfc;

    constructor(uint256 __validatorID, string memory __description,
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd,
        address __sfc, address verifier) public {
        _name = string(abi.encodePacked("Refund for Slashed Validator #", uint256ToStr(__validatorID)));
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

    function pType() public view returns (uint256) {
        return 5003;
    }

    function execute_delegatecall(address selfAddr, uint256 optionID) external {
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

    function uint256ToStr(uint256 num) internal pure returns (string memory) {
        if (num == 0) {
            return "0";
        }
        uint decimals = decimalsNum(num);
        bytes memory bstr = new bytes(decimals);
        uint strIdx = decimals - 1;
        while (num != 0) {
            bstr[strIdx] = byte(uint8(48 + num % 10));
            num /= 10;
            strIdx--;
        }
        return string(bstr);
    }
}