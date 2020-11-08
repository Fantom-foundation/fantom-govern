# Governance contract

Governance contract supports on-chain voting by arbitrary members on arbitrary topics. Each voting topic is called a "proposal".

The contract is designed to be universal and flexible:
- The governance isn't coupled to any specific staking contract, but relies on an interface to get voter weights.
- It supports multi-delegations between voters. A voter can delegate their vote to another voter.
- It supports on-chain execution of the proposals. On approval, each proposal may perform arbitrary actions on behalf of the governance contract.
- The contract permits multiple options for proposals, and multiple degrees of an agreement for each vote.
- An arbitrary number of proposal templates are permitted. Each proposal can specify its parameters (such as voting turnout or deadlines) within the boundaries of a template.
- It can handle an arbitrary number of active proposals simultaneously.
- The contract can also support an arbitrary number of active voters simultaneously.

## Wiki

Check out the wiki to get more details.

# Test

1. Install nodejs 10.5.0
2. `npm install -g truffle@v5.1.4` # install truffle v5.1.4
3. `npm update`
4. `npm test`

If everything is allright, it should output something along this:
```
> governance@1.0.0 test /home/up/w/fantom-govern
> truffle test


Compiling your contracts...
===========================
> Compiling ./contracts/Migrations.sol
> Compiling ./contracts/common/Decimal.sol
> Compiling ./contracts/common/GetCode.sol
> Compiling ./contracts/common/ReentrancyGuard.sol
> Compiling ./contracts/common/SafeMath.sol
> Compiling ./contracts/governance/Constants.sol
> Compiling ./contracts/governance/Governance.sol
> Compiling ./contracts/governance/GovernanceSettings.sol
> Compiling ./contracts/governance/LRC.sol
> Compiling ./contracts/governance/Proposal.sol
> Compiling ./contracts/governance/ProposalTemplates.sol
> Compiling ./contracts/model/Governable.sol
> Compiling ./contracts/ownership/Ownable.sol
> Compiling ./contracts/proposal/BaseProposal.sol
> Compiling ./contracts/proposal/IProposal.sol
> Compiling ./contracts/proposal/IProposalVerifier.sol
> Compiling ./contracts/proposal/PlainTextProposal.sol
> Compiling ./contracts/proposal/SoftwareUpgradeProposal.sol
> Compiling ./contracts/test/AlteredPlainTextProposal.sol
> Compiling ./contracts/test/ExecLoggingProposal.sol
> Compiling ./contracts/test/ExplicitProposal.sol
> Compiling ./contracts/test/UnitTestGovernable.sol
> Compiling ./contracts/test/UnitTestGovernance.sol
> Compiling ./contracts/upgrade/Upgradability.sol
> Compiling ./contracts/version/Version.sol



  Contract: Governance test
    ✓ checking deployment of a plaintext proposal contract (1686ms)
    ✓ checking creation of a plaintext proposal (1208ms)
    ✓ checking proposal verification with explicit timestamps and opinions (997ms)
    ✓ checking self-vote creation (589ms)
    ✓ checking voting tally for a self-voter (938ms)
    ✓ checking proposal execution via call (427ms)
    ✓ checking proposal execution via delegatecall (440ms)
    ✓ checking proposal rejecting before max voting end is reached (369ms)
    ✓ checking voting tally with low turnout (456ms)
    ✓ checking execution expiration (438ms)
    ✓ checking proposal is rejected if low agreement after max voting end (408ms)
    ✓ checking proposal is rejected if low turnout after max voting end (555ms)
    ✓ checking execution doesn't expire earlier than needed (411ms)
    ✓ checking proposal cancellation (702ms)
    ✓ checking handling multiple tasks (1822ms)
    ✓ checking delegation vote creation (828ms)
    ✓ checking voting with custom parameters (607ms)
    ✓ checking OwnableVerifier (850ms)
    checking votes for a self-voter
      ✓ checking voting state (293ms)
      ✓ cancel vote (110ms)
      ✓ recount vote (380ms)
      ✓ cancel vote via recounting (94ms)
    checking votes for 1 delegation and 2 self-voters
      ✓ cancel votes (229ms)
      ✓ cancel votes in reversed order (131ms)
      ✓ checking voting state (311ms)
      ✓ checking voting state after delegator re-voting (472ms)
      ✓ checking voting state after first voter re-voting (392ms)
      ✓ checking voting state after second voter re-voting (403ms)
      ✓ checking voting state after delegator vote canceling (237ms)
      ✓ checking voting state after first staker vote canceling (291ms)
      ✓ checking voting state after delegator recounting (362ms)
      ✓ checking voting state after first staker recounting (300ms)
      ✓ checking voting state after cross-delegations between voters (679ms)
      ✓ cancel votes via recounting (200ms)
      ✓ cancel votes via recounting gradually (213ms)
      ✓ cancel votes via recounting in reversed order (328ms)
      ✓ cancel votes via recounting gradually in reversed order (251ms)
    checking votes for 2 self-voters and 1 delegation
      ✓ cancel votes (205ms)
      ✓ cancel votes in reversed order (212ms)
      ✓ checking voting state (334ms)
      ✓ checking voting state after delegator re-voting (481ms)
      ✓ checking voting state after first voter re-voting (410ms)
      ✓ checking voting state after second voter re-voting (440ms)
      ✓ checking voting state after delegator vote canceling (247ms)
      ✓ checking voting state after first staker vote canceling (231ms)
      ✓ checking voting state after delegator recounting (360ms)
      ✓ checking voting state after first staker recounting (311ms)
      ✓ checking voting state after cross-delegations between voters (616ms)
      ✓ cancel votes via recounting (203ms)
      ✓ cancel votes via recounting gradually (242ms)
      ✓ cancel votes via recounting in reversed order (221ms)
      ✓ cancel votes via recounting gradually in reversed order (267ms)


  52 passing (1m)
```
