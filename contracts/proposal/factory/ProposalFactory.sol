pragma solidity ^0.5.0;

import "../../common/SafeMath.sol";
import "../../ownership/Ownable.sol";
import "../../proposal/NetworkParameterProposal.sol";
import "../../proposal/PlainTextProposal.sol";

interface IGovernance {
    function createProposal(address proposalAddress) external payable;
    function proposalFee() external returns (uint256);
}

contract ProposalFactory is Ownable {
    using SafeMath for uint256;

    event NetworkParameterProposalDeployed(address _address);
    event PlaintextProposalDeployed(address _address);
    event ProposalDisabled(address _address);

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

    address public lastNetworkProposal;
    address public lastPlainTextProposal;
    address public governance;

    constructor(address _governance) public {
        governance = _governance;
        initialize(msg.sender);
    }

    function deployNewNetworkParameterProposal(
        string memory __name, string memory __description, bytes32[] memory __options, 
        uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd,
        address __sfc, address verifier, string memory __signature, uint256[] memory __optionsList, 
        Proposal.ExecType __exec, uint256[] memory __scales) public payable {

        require(
            msg.value >= (IGovernance(governance)).proposalFee(),
            "insufficient fee"
        );
        
        NetworkParameterProposal _deployedProposal = new NetworkParameterProposal(__exec, __scales, __sfc, address(this));
        _deployedProposal.transferOwnership(msg.sender);

        lastNetworkProposal = address(_deployedProposal);

        Proposals storage proposal = proposals[lastNetworkProposal];

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

        exists[lastNetworkProposal] = true;

        (NetworkParameterProposal(lastNetworkProposal)).init(verifier);

        (IGovernance(governance)).createProposal.value(msg.value)(
            lastNetworkProposal
        );
        
        emit NetworkParameterProposalDeployed(lastNetworkProposal);
    }

     function deployNewPlainTextProposal(string calldata __name, string calldata __description, bytes32[] calldata __options,
         uint256 __minVotes, uint256 __minAgreement, uint256 __start, uint256 __minEnd, uint256 __maxEnd) payable external {

        require(
            msg.value >= (IGovernance(governance)).proposalFee(),
            "insufficient fee"
        );

         uint256[] memory params = new uint256[](5);
         params[0] = __minVotes;
         params[1] = __minAgreement;
         params[2] = __start;
         params[3] = __minEnd;
         params[4] = __maxEnd;

         _create(__name, __description, __options, params);
     }

     function _create(string memory __name, string memory __description, bytes32[] memory __options, uint256[] memory params) internal {
         PlainTextProposal _deployedProposal = new PlainTextProposal(__name, __description, __options,
             params[0], params[1], params[2], params[3], params[4], address(0));
         _deployedProposal.transferOwnership(msg.sender);
         lastPlainTextProposal = address(_deployedProposal);

         Proposals storage proposal = proposals[lastPlainTextProposal];

         proposal._name = __name;
         proposal._description = __description;
         proposal._options = __options;
         proposal._minVotes = params[0];
         proposal._minAgreement = params[1];
         proposal._start = params[2];
         proposal._minEnd = params[3];
         proposal._maxEnd = params[4];

         exists[lastPlainTextProposal] = true;

         (IGovernance(governance)).createProposal.value(msg.value)(address(_deployedProposal));

         emit PlaintextProposalDeployed(address(_deployedProposal));
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
        emit ProposalDisabled(proposalContractAddress);
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
