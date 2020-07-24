# Governance contract

Governance contract supports on-chain voting by Fantom token holders on arbitrary topics. Each voting topic is called called a "proposal".

The contract is designed to be universal and flexible:
- The governance isn't coupled to any specific staking contract, but relies on an interface to get voter weights.
- It supports multi-delegations between voters. A voter can delegate their vote to another voter.
- It supports on-chain execution of the proposals. On approval, each proposal may perform arbitrary actions on behalf of the governance contract.
- The contract permits multiple options for proposals, and multiple degrees of an agreement for each vote.
- An arbitrary number of proposal templates are permitted. Each proposal can specify its parameters (such as voting turnout or deadlines) within the boundaries of a template.
- It can handle an arbitrary number of active proposals simultaneously.
- The contract can also support an arbitrary number of active voters simultaneously.

## Integration interface

A Governance relies on the Governable interface to get voter weights.

A naive example of a governable contract may be found in UnitTestGovernable.

## Submitting a proposal

Any FTM token holder is allowed to submit a proposal. Each proposal submission will require a cost (called fee), which is a contract instant. Proposal fee will get burnt during the operation.

## Delegations

Within a governable contract, voters can get delegations from other voters.

When voter makes a vote, the contract assumes that all his delegators agree with it, effectively increasing vote's weight. If a delegator doesn't agree with the opinions of a voter he delegated to, then he can override it with his own vote.

## Proposal templates

Each proposal is defined by its proposal contract. A proposal contract holds proposal parameters and it may define an execution logic, if the proposal is executable.

Proposals are defined by contracts, and there are some constraints imposed on them.

To define such proposal constraints, proposal templates are used. Each proposal template defines the following conditions:
- Contract bytecode: If defined, then proposal's code must match to this example.
- Executable (bool): True if proposal should get executed on approval.
- MinVotes (ratio): Minimum voting turnout.
- minAgreement (ratio): Minimum allowed `Minimum voting agreement`.
- opinionScales (uint[]): Each opinion scale defines an exact measure of agreement which voter may choose.
- minVotingDuration (seconds): Minimum duration of the voting.
- maxVotingDuration (seconds): Maximum duration of the voting.
- minStartDelay (seconds): Minimum delay of the voting (i.e. must start with a delay).
- maxStartDelay (seconds): Maximum delay of the voting (i.e. must start sooner).

Some examples of proposal templates:
1. Unknown non-executable: These proposals aren't executable and are unlikely to break anything. Thus, the requirements above are not very strict.
2. Unknown executable: Proposals of this kind are executable and their bytecode can be arbitrary. The requirements above must be specified as strict as possible.
3. Depositing proposal: Such proposals gather funds and allow to transfer them to a specific address after proposal approval. These proposals are executable but have a verified bytecode, and thus the requirements above are moderately strict.

Addition to the new templates may be done within an executable proposal.

## What proposals can do

If proposal is executable, then it may perform arbitrary actions on behalf of the governance contract.

Some proposal templates require a specific bytecode, which may limit the freedom of possible actions.

## Voting model

#### Options and opinions

Each proposal defines a list of options. Voter must provide a single opinion for each option during the voting for a proposal.

Opinion is recorded as a number within [0, number of opinions).

For example, let's consider an example proposal that has 3 options and the following opinion scales {0, 2, 3, 4, 5} to represent {strongly disagree, disagree, neutral, agree and strongly agree}.

A vote {0, 2, 4} from a voter has the following meaning: `I strongly disagree (scale=0) with option 0, I'm neutral (scale=3) about option 1, I strongly agree (scale=5) with option 2`.

If we also assume that voter had a weight=100.0, then he added the following agreement to a counter of each option: `0 * 100.0 / 5 = 0` for option 0, `3 * 100.0 / 5 = 60` for option 1, `5 * 100.0 / 5 = 100` for option 2.

That being said, the opinion scale defines an exact measure of agreement which voter may choose.

#### Voting tally

Each proposal has the following parameters, which define requirements for the proposal to get approved:
- Minimum voting turnout (min. votes)
- Minimum voting agreement
- Minimum voting end time
- Maximum voting end time

Minimum voting turnout is minimum ratio of `voted voters weight`/`total voters weight` to perform the voting tally.
Maximum voting end time is the earliest possible time to perform the voting tally.
Minimum voting agreement is the minimum value of `agreement counter`/`voted voters weight` for an option to possibly win.
Maximum voting end time is the the latest possible time to perform the voting tally. If proposal wasn't accepted and this period has passed, then it'll get rejected during the task handling.

If no option received an agreement ratio higher than `Minimum voting agreement`, then proposal gets rejected.
Otherwise, an option with maximum agreement wins the election.

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


  32 passing (39s)
```
