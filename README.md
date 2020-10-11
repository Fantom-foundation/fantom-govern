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
    ✓ checking deployment of a plaintext proposal contract (1682ms)
    ✓ checking creation of a plaintext proposal (1162ms)
    ✓ checking proposal verification with explicit timestamps and opinions (1046ms)
    ✓ checking self-vote creation (580ms)
    ✓ checking voting tally for a self-voter (949ms)
    ✓ checking proposal execution via call (443ms)
    ✓ checking proposal execution via delegatecall (407ms)
    ✓ checking proposal rejecting before max voting end is reached (413ms)
    ✓ checking voting tally with low turnout (486ms)
    ✓ checking execution expiration (419ms)
    ✓ checking proposal is discarded if low enough agreement after expiration period (401ms)
    ✓ checking execution doesn't expire earlier than needed (388ms)
    ✓ checking proposal cancellation (716ms)
    ✓ checking handling multiple tasks (2077ms)
    ✓ checking delegation vote creation (904ms)
    ✓ checking voting with custom parameters (586ms)
    checking votes for a self-voter
      ✓ checking voting state (154ms)
      ✓ cancel vote (115ms)
      ✓ recount vote (391ms)
      ✓ cancel vote via recounting (97ms)
    checking votes for 2 self-voters and 1 delegation
      ✓ cancel votes (226ms)
      ✓ cancel votes in reversed order (156ms)
      ✓ checking voting state (342ms)
      ✓ checking voting state after delegator re-voting (528ms)
      ✓ checking voting state after first voter re-voting (432ms)
      ✓ checking voting state after second voter re-voting (465ms)
      ✓ checking voting state after delegator vote canceling (314ms)
      ✓ checking voting state after first staker vote canceling (267ms)
      ✓ checking voting state after delegator recounting (402ms)
      ✓ checking voting state after first staker recounting (344ms)
      ✓ checking voting state after cross-delegations between voters (604ms)
      ✓ cancel votes via recounting (238ms)
      ✓ cancel votes via recounting gradually (233ms)
      ✓ cancel votes via recounting in reversed order (262ms)
      ✓ cancel votes via recounting gradually in reversed order (294ms)


  35 passing (39s)
```
