pragma solidity ^0.5.0;

import "./base/Cancelable.sol";
import "./base/DelegatecallExecutableProposal.sol";

interface IProposalFactory {
    function getProposalName(address) external view returns(string memory);
    function getProposalDescription(address) external view returns(string memory);
    function getProposalSignature(address) external view returns(string memory);
    function getProposalMinVotes(address) external view returns(uint256);
    function getProposalMinAgreement(address) external view returns(uint256);
    function getProposalStart(address) external view returns(uint256);
    function getProposalMinEnd(address) external view returns(uint256);
    function getProposalMaxEnd(address) external view returns(uint256);
    function getProposalOptions(address) external view returns(bytes32[] memory);
    function getProposalOptionsList(address) external view returns(uint256[] memory);
}

/**
 * @dev NetworkParameterProposal proposal
 */
contract NetworkParameterProposal is DelegatecallExecutableProposal, Cancelable {
    Proposal.ExecType _exec;
    address public sfcAddress;
    IProposalFactory public proposalFactory;
    /**
     * @param functionSignature Target function declaration
     * @notice Set in the constructor; available options:
     * `setMaxDelegation(uint256)`
     * `setValidatorCommission(uint256)`
     * `setContractCommission(uint256)`
     * `setUnlockedRewardRatio(uint256)`
     * `setMinLockupDuration(uint256)`
     * `setMaxLockupDuration(uint256)`
     * `setWithdrawalPeriodEpoch(uint256)`
     * `setWithdrawalPeriodTime(uint256)`
     */
    string public functionSignature;
    uint256[] public optionsList;

    constructor(Proposal.ExecType __exec, uint256[] memory __scales, address __sfc, address __proposalFactory) public {
        proposalFactory = IProposalFactory(__proposalFactory);
        sfcAddress = __sfc;
        _exec = __exec;
        _opinionScales = __scales;
        // verify the proposal right away to avoid deploying a wrong proposal
        // if (verifier != address(0)) {
        //     require(verifyProposalParams(verifier), "failed verification");
        // }
    }

    function init(address verifier) external {
        _name = proposalFactory.getProposalName(address(this));
        _description = proposalFactory.getProposalDescription(address(this));
        functionSignature = proposalFactory.getProposalSignature(address(this));
        _minVotes = proposalFactory.getProposalMinVotes(address(this));
        _minAgreement = proposalFactory.getProposalMinAgreement(address(this));
        _start = proposalFactory.getProposalStart(address(this));
        _minEnd = proposalFactory.getProposalMinEnd(address(this));
        _maxEnd = proposalFactory.getProposalMaxEnd(address(this));
        _options = proposalFactory.getProposalOptions(address(this));
        optionsList = proposalFactory.getProposalOptionsList(address(this));
        // double-check proposal params after initializing from factory
        if (verifier != address(0)) {
            require(verifyProposalParams(verifier), "failed verification");
        }
    }

    function pType() public view returns (uint256) {
        return 15;
    }

    function executable() public view returns (Proposal.ExecType) {
        return _exec;
    }

    event NetworkParameterUpgradeIsDone(uint256 newValue);

    function execute_delegatecall(address selfAddr, uint256 winnerOptionID) external {
        NetworkParameterProposal self = NetworkParameterProposal(selfAddr);
        self.sfcAddress().call(abi.encodeWithSignature(self.functionSignature(), self.optionsList(winnerOptionID)));
        emit NetworkParameterUpgradeIsDone(self.optionsList(winnerOptionID));
    }
}