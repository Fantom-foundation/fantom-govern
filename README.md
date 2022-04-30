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

1. Install nodejs
2. `npm install`
3. `npx hardhat compile`
4. `npx hardhat node`
5. `npx hardhat test`

If everything is alright, it should output something along this:

```
Compiling your contracts...
===========================
  Contract: Governance test
    ✔ checking deployment of a plaintext proposal contract (751ms)
    ✔ checking creation of a plaintext proposal (477ms)
    ✔ checking proposal verification with explicit timestamps and opinions (223ms)
    ✔ checking self-vote creation (191ms)
    ✔ checking voting tally for a self-voter (330ms)
    ✔ checking proposal execution via call (112ms)
    ✔ checking proposal execution via delegatecall (110ms)
    ✔ checking proposal rejecting before max voting end is reached (99ms)
    ✔ checking voting tally with low turnout (140ms)
    ✔ checking execution expiration (106ms)
    ✔ checking proposal is rejected if low agreement after max voting end (100ms)
    ✔ checking proposal is rejected if low turnout after max voting end (105ms)
    ✔ checking execution doesn't expire earlier than needed (111ms)
    ✔ checking proposal cancellation (183ms)
    ✔ checking handling multiple tasks (534ms)
    ✔ checking delegation vote creation (345ms)
    ✔ checking voting with custom parameters (195ms)
    ✔ checking OwnableVerifier (416ms)
    checking votes for a self-voter
      ✔ checking voting state (42ms)
      ✔ cancel vote (43ms)
      ✔ recount vote (133ms)
      ✔ cancel vote via recounting
    checking votes for 1 delegation and 2 self-voters
      ✔ cancel votes (84ms)
      ✔ cancel votes in reversed order (60ms)
      ✔ checking voting state (97ms)
      ✔ checking voting state after delegator re-voting (167ms)
      ✔ checking voting state after first voter re-voting (132ms)
      ✔ checking voting state after second voter re-voting (133ms)
      ✔ checking voting state after delegator vote canceling (79ms)
      ✔ checking voting state after first staker vote canceling (79ms)
      ✔ checking voting state after delegator recounting (148ms)
      ✔ checking voting state after first staker recounting (110ms)
      ✔ checking voting state after cross-delegations between voters (228ms)
      ✔ cancel votes via recounting (73ms)
      ✔ cancel votes via recounting gradually (73ms)
      ✔ cancel votes via recounting in reversed order (84ms)
      ✔ cancel votes via recounting gradually in reversed order (105ms)
    checking votes for 2 self-voters and 1 delegation
      ✔ cancel votes (73ms)
      ✔ cancel votes in reversed order (62ms)
      ✔ checking voting state (99ms)
      ✔ checking voting state after delegator re-voting (187ms)
      ✔ checking voting state after first voter re-voting (145ms)
      ✔ checking voting state after second voter re-voting (155ms)
      ✔ checking voting state after delegator vote canceling (98ms)
      ✔ checking voting state after first staker vote canceling (92ms)
      ✔ checking voting state after delegator recounting (169ms)
      ✔ checking voting state after first staker recounting (123ms)
      ✔ checking voting state after cross-delegations between voters (279ms)
      ✔ cancel votes via recounting (94ms)
      ✔ cancel votes via recounting gradually (97ms)
      ✔ cancel votes via recounting in reversed order (105ms)
      ✔ cancel votes via recounting gradually in reversed order (124ms)


  52 passing (22s)
```
