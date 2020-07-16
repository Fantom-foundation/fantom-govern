pragma solidity ^0.5.0;

import "../common/SafeMath.sol";
import "../governance/Constants.sol";
import "../model/Governable.sol";
import "../upgrade/Upgradability.sol";
import "../proposal/AbstractProposal.sol";


/**
 * @dev PlainText proposal
 */
contract PlainTextProposal is AbstractProposal {
    using SafeMath for uint256;

    bytes32 title;
    bytes32 description;
    bytes32[] options;

    event ProposalAccepted(uint256 optionId);

    constructor(bytes32 _title, bytes32 _description, bytes32[] memory _options) public {
        _title = title;
        description = _description;
        options = _options;
    }

    function validateProposal(bytes32) public {

    }

    function getOptions() public returns (bytes32[] memory) {
        return options;
    }

    function execute(uint256 optionId) public {
        emit ProposalAccepted(optionId);
    }
}