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

# Compile
To compile the contracts, run: `make`

# Test
To run hardhat tests, run: `make test`\
Make sure you compile the contracts first. 

If everything is all right, it should output something along this:
```
  Governance test
    ✔ checking deployment of a plaintext proposal contract (107ms)
    ✔ checking creation of a plaintext proposal (54ms)
    ✔ checking proposal verification with explicit timestamps and opinions
    ✔ checking creation and execution of network parameter proposals via proposal factory
    ✔ checking self-vote creation
    ✔ checking voting tally for a self-voter
    ✔ checking proposal execution via call
    ✔ checking proposal execution via delegatecall
    ✔ checking non-executable proposal resolving
    ✔ checking proposal rejecting before max voting end is reached
    ✔ checking voting tally with low turnout
    ✔ checking execution expiration
    ✔ checking proposal is rejected if low agreement after max voting end
    ✔ checking execution doesn't expire earlier than needed
    ✔ checking proposal cancellation
    ✔ checking handling multiple tasks (62ms)
    ✔ checking proposal is rejected if low turnout after max voting end
    ✔ checking delegation vote creation (40ms)
    ✔ checking voting with custom parameters
    ✔ checking OwnableVerifier (61ms)
    ✔ checking SlashingRefundProposal naming scheme (42ms)
    checking votes for a self-voter
      ✔ checking voting state
      ✔ cancel vote
      ✔ recount vote
      ✔ cancel vote via recounting
      ✔ cancel vote via recounting from VotesBookKeeper
    checking votes for 1 delegation and 2 self-voters
      ✔ cancel votes
      ✔ cancel votes in reversed order
      ✔ checking voting state
      ✔ checking voting state after delegator re-voting
      ✔ checking voting state after first voter re-voting
      ✔ checking voting state after second voter re-voting
      ✔ checking voting state after delegator vote canceling
      ✔ checking voting state after first staker vote canceling
      ✔ checking voting state after delegator recounting
      ✔ checking voting state after first staker recounting
      ✔ checking voting state after cross-delegations between voters
      ✔ cancel votes via recounting
      ✔ cancel votes via recounting gradually
      ✔ cancel votes via recounting in reversed order
      ✔ cancel votes via recounting gradually in reversed order
    checking votes for 2 self-voters and 1 delegation
      ✔ cancel votes
      ✔ cancel votes in reversed order
      ✔ checking voting state
      ✔ checking voting state after delegator re-voting
      ✔ checking voting state after first voter re-voting
      ✔ checking voting state after second voter re-voting
      ✔ checking voting state after delegator vote canceling
      ✔ checking voting state after first staker vote canceling
      ✔ checking voting state after delegator recounting
      ✔ checking voting state after first staker recounting
      ✔ checking voting state after cross-delegations between voters
      ✔ cancel votes via recounting
      ✔ cancel votes via recounting gradually
      ✔ cancel votes via recounting in reversed order
      ✔ cancel votes via recounting gradually in reversed order

  VotesBookKeeper
    ✔ onVoted() should record two votes from one voter to two different proposals
    ✔ onVoted() should revert when received too many votes from one voter
    ✔ onVoteCanceled() removes vote
    ✔ checking VotesBookKeeper proposals cap
    ✔ checking VotesBookKeeper pruning outdated votes
    ✔ checking VotesBookKeeper indexes


  62 passing (2s)
```
