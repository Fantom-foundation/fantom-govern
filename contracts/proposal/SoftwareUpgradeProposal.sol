pragma solidity ^0.5.0;

import "../upgrade/Upgradability.sol";
import "./base/Cancelable.sol";
import "./base/DelegatecallExecutableProposal.sol";

/**
 * @dev SoftwareUpgrade proposal
 */
contract SoftwareUpgradeProposal is DelegatecallExecutableProposal, Cancelable {
    address public upgradeableContract;
    address public newImplementation;

    constructor(
        string memory __name,
        string memory __description,
        uint256 __minVotes,
        uint256 __minAgreement,
        uint256 __start,
        uint256 __minEnd,
        uint256 __maxEnd,
        address __upgradeableContract,
        address __newImplementation,
        address verifier
    ) public {
        _name = __name;
        _description = __description;
        _options.push(bytes32("yes"));
        _minVotes = __minVotes;
        _minAgreement = __minAgreement;
        _opinionScales = [0, 1, 2, 3, 4];
        _start = __start;
        _minEnd = __minEnd;
        _maxEnd = __maxEnd;
        upgradeableContract = __upgradeableContract;
        newImplementation = __newImplementation;
        // verify the proposal right away to avoid deploying a wrong proposal
        string memory message;
        if (verifier != address(0)) {
            message = verifyProposalParams(verifier);
            require(bytes(message).length == 0, message);
        }
    }

    event SoftwareUpgradeIsDone(address newImplementation);

    function execute_delegatecall(address selfAddr, uint256) external {
        SoftwareUpgradeProposal self = SoftwareUpgradeProposal(selfAddr);
        Upgradability(self.upgradeableContract()).upgradeTo(
            self.newImplementation()
        );
        emit SoftwareUpgradeIsDone(self.newImplementation());
    }
}
