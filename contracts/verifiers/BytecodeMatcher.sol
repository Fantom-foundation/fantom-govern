pragma solidity ^0.5.0;

import "../common/GetCode.sol";
import "../governance/Proposal.sol";
import "./IProposalVerifier.sol";
import "../common/Initializable.sol";

contract BytecodeMatcher is IProposalVerifier, Initializable {
    using GetCode for address;

    address public codeSample;
    bytes32 public codeHash;

    function initialize(address _codeSample) public initializer {
        codeSample = _codeSample;
        codeHash = codeSample.codeHash();
    }

    // verifyProposalParams checks proposal code and parameters
    function verifyProposalParams(uint256, Proposal.ExecType, uint256, uint256, uint256[] calldata, uint256, uint256, uint256) external view returns (bool) {
        return true;
    }

    // verifyProposalContract verifies proposal code from the specified type and address
    function verifyProposalContract(uint256, address propAddr) external view returns (bool) {
        return propAddr.codeHash() == codeHash;
    }
}
