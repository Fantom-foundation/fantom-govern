pragma solidity ^0.5.0;

library Proposal {
    struct Timeline {
        uint256 votingStartTime; // date when the voting starts
        uint256 votingMinEndTime; // date of earliest possible voting end
        uint256 votingMaxEndTime; // date of longest possible voting end
    }

    struct Parameters {
        Timeline deadlines;
        uint256 pType; // type of proposal (e.g. plaintext, software upgrade)
        bool executable; // if proposal should get executed if gets approved
        uint256 minVotes; // min. quorum (ratio)
        address propContract; // contract which stores the proposal data and executes its logic
    }
}
