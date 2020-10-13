pragma solidity ^0.5.0;

import "../PlainTextProposal.sol";

contract AlteredPlainTextProposal is PlainTextProposal {
    constructor(string memory v1, string memory v2, bytes32[] memory v3,
        uint256 v4, uint256 v5, uint256 v6, uint256 v7, uint256 v8, address v9) PlainTextProposal(v1, v2, v3, v4, v5, v6, v7, v8, v9) public {}

    function name() public view returns (string memory) {
        return "altered";
    }
}
