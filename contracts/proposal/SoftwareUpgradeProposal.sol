pragma solidity ^0.5.0;

import "../upgrade/Upgradability.sol";
import "./BaseProposal.sol";
import "./Cancelable.sol";

/**
 * @dev SoftwareUpgrade proposal
 */
contract SoftwareUpgradeProposal is BaseProposal, Cancelable {
    address public upgradableContract;
    address public newImplementation;

    constructor(string memory __name, string memory __description,
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd,
        address __upgradableContract, address __newImplementation, address verifier) public {
        _name = __name;
        _description = __description;
        _options.push(bytes32("upgrade"));
        _minVotes = __minVotes;
        _minAgreement = __minAgreement;
        _opinionScales = [0, 2, 3, 4, 5];
        _start = __start;
        _minEnd = __minEnd;
        _maxEnd = __maxEnd;
        upgradableContract = __upgradableContract;
        newImplementation = __newImplementation;
        // verify the proposal right away to avoid deploying a wrong proposal
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed validation");
        }
    }

    function pType() public view returns (uint256) {
        return uint256(StdProposalTypes.SOFTWARE_UPGRADE);
    }

    function executable() public view returns (Proposal.ExecType) {
        return Proposal.ExecType.DELEGATECALL;
    }

    event SoftwareUpgradeIsDone(address newImplementation);

    function execute_delegatecall(address selfAddr, uint256) external {
        SoftwareUpgradeProposal self = SoftwareUpgradeProposal(selfAddr);
        Upgradability(self.upgradableContract()).upgradeTo(self.newImplementation());
        emit SoftwareUpgradeIsDone(self.newImplementation());
    }
}