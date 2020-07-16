pragma solidity ^0.5.0;

import "../common/SafeMath.sol";
import "../governance/Constants.sol";
import "../model/Governable.sol";
import "../upgrade/Upgradability.sol";
import "../proposal/AbstractProposal.sol";


/**
 * @dev SoftwareUpgrade proposal
 */ 
contract SoftwareUpgradeProposal is AbstractProposal {

    Upgradability upgradableContract;
    address newContractAddress;
    bytes32[] opts;

    event SoftwareUpgradeIsDone();

    constructor(address upgradableAddr, address _newContractAddr) public {
        upgradableContract = Upgradability(upgradableAddr);
        newContractAddress = _newContractAddr;

        bytes32 voteYes = "yes";
        bytes32 voteNo = "no";
        opts.push(voteYes);
        opts.push(voteNo);
    }

    function validateProposal(bytes32) public {

    }

    function getOptions() public returns (bytes32[] memory) {

        return opts;
    }

    function execute(uint256 optionId) public {
        upgradableContract.upgradeTo(newContractAddress);
        emit SoftwareUpgradeIsDone();
    }
}