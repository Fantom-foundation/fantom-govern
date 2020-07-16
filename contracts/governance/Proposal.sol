pragma solidity ^0.5.0;

library Proposal {
    struct Timeline {
        uint256 votingStartTime; // date when the voting starts
        uint256 votingMinEndTime; // date of earliest possible voting end
        uint256 votingMaxEndTime; // date of latest possible voting end
    }

    struct Parameters {
        uint256 pType; // type of proposal (e.g. plaintext, software upgrade)
        bool executable; // true if proposal should get executed on approval
        uint256 minVotes; // min. quorum (ratio)
        address proposalContract; // contract which stores the proposal data and executes its logic
        Timeline deadlines;
    }
}
