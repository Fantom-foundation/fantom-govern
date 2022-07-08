pragma solidity ^0.5.0;

import "../../common/SafeMath.sol";
import "../../ownership/Ownable.sol";
import "../../proposal/NetworkParameterProposal.sol";

contract ProposalFactory is Ownable {
    using SafeMath for uint256;

    event NetworkParameterProposalDeployed(address _address);
    event NetworkParameterProposalDisabled(address _address);

    struct Proposals {
        string _name;
        string _description;
        bytes32[] _options;
        uint256 _minVotes;
        uint256 _minAgreement;
        uint256 _start;
        uint256 _minEnd;
        uint256 _maxEnd;
        string _signature;
        uint256[] _optionsList;
        bool _deployed;
    }

    mapping (address => Proposals) public proposals;
    mapping (address => bool) public exists;

    address public lastProposal;

    function initialize() public initializer {
        Ownable.initialize(msg.sender);
    }

    function deployNewNetworkParameterProposal(
        string memory __name, string memory __description, bytes32[] memory __options, 
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd,
        address __sfc, address verifier, string memory __signature, uint256[] memory __optionsList, 
        Proposal.ExecType __exec, uint256[] memory __scales) public onlyOwner {
        
        address _deployedProposal = address(new NetworkParameterProposal(__exec, __options, __scales, verifier, __sfc, address(this)));

        Proposals storage proposal = proposals[_deployedProposal];

        proposal._name = __name;
        proposal._description = __description;
        proposal._options = __options;
        proposal._minVotes = __minVotes;
        proposal._minAgreement = __minAgreement;
        proposal._start = __start;
        proposal._minEnd = __minEnd;
        proposal._maxEnd = __maxEnd;
        proposal._signature = __signature;
        proposal._optionsList = __optionsList;

        exists[_deployedProposal] = true;

        lastProposal = _deployedProposal;
        (NetworkParameterProposal(_deployedProposal)).init(verifier);
        
        emit NetworkParameterProposalDeployed(_deployedProposal);
    }

    /// @notice Method for registering existing NetworkParameterProposal contract
    /// @param  proposalContractAddress Address of networkProposal contract
    function registerProposalContract(address proposalContractAddress)
        external
        onlyOwner
    {
        require(
            !exists[proposalContractAddress],
            "Proposal contract already registered"
        );

        exists[proposalContractAddress] = true;
        emit NetworkParameterProposalDeployed(proposalContractAddress);
    }

    /// @notice Method for disabling existing NetworkParameterProposal contract
    /// @param  proposalContractAddress Address of networkProposal contract
    function disableProposalContract(address proposalContractAddress)
        external
        onlyOwner
    {
        require(
            exists[proposalContractAddress],
            "Proposal contract is not registered"
        );
        
        exists[proposalContractAddress] = false;
        emit NetworkParameterProposalDisabled(proposalContractAddress);
    }

    /** Getter Functions */

    function getProposalName(address _address) external view returns(string memory) {
        return(proposals[_address]._name);
    }

    function getProposalDescription(address _address) external view returns(string memory) {
        return(proposals[_address]._description);
    }

    function getProposalSignature(address _address) external view returns(string memory) {
        return(proposals[_address]._signature);
    }

    function getProposalMinVotes(address _address) external view returns(uint256) {
        return(proposals[_address]._minVotes);
    }

    function getProposalMinAgreement(address _address) external view returns(uint256) {
        return(proposals[_address]._minAgreement);
    }

    function getProposalStart(address _address) external view returns(uint256) {
        return(proposals[_address]._start);
    }

    function getProposalMinEnd(address _address) external view returns(uint256) {
        return(proposals[_address]._minEnd);
    }

    function getProposalMaxEnd(address _address) external view returns(uint256) {
        return(proposals[_address]._maxEnd);
    }

    function getProposalOptions(address _address) external view returns(bytes32[] memory) {
        return(proposals[_address]._options);
    }

    function getProposalOptionsList(address _address) external view returns(uint256[] memory) {
        return(proposals[_address]._optionsList);
    }
}
