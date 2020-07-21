pragma solidity ^0.5.0;

import "../upgrade/Upgradability.sol";
import "./BaseProposal.sol";

/**
 * @dev SoftwareUpgrade proposal
 */
contract SoftwareUpgradeProposal is BaseProposal {
    Upgradability public upgradableContract;
    address public newContractAddress;

    constructor(string memory __name, string memory __description,
        uint256 __minVotes, uint256 __start, uint256 __minEnd, uint256 __maxEnd,
        address __upgradableContract, address __newContractAddress, address verifier) public {
        _name = __name;
        _description = __description;
        _options.push(bytes32("upgrade"));
        _minVotes = __minVotes;
        _start = __start;
        _minEnd = __minEnd;
        _maxEnd = __maxEnd;
        upgradableContract = Upgradability(__upgradableContract);
        newContractAddress = __newContractAddress;

        // verify the proposal right away
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed validation");
        }
    }

    function pType() public view returns (StdProposalTypes) {
        return StdProposalTypes.SOFTWARE_UPGRADE;
    }

    function executable() public view returns (bool) {
        return true;
    }

    event SoftwareUpgradeIsDone(address newContractAddress);

    function execute(address, uint256) external {
        upgradableContract.upgradeTo(newContractAddress);
        emit SoftwareUpgradeIsDone(newContractAddress);
    }
}