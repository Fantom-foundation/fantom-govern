pragma solidity ^0.5.0;

import "../proposal/base/IProposal.sol";

library Proposal {
    struct Timeline {
        uint256 votingStartTime; // date when the voting starts
        uint256 votingMinEndTime; // date of earliest possible voting end
        uint256 votingMaxEndTime; // date of latest possible voting end
    }

    enum ExecType {
        NONE,
        CALL,
        DELEGATECALL
    }

    struct Parameters {
        uint256 pType; // type of proposal (e.g. plaintext, software upgrade)
        ExecType executable; // proposal execution type when proposal gets resolved
        uint256 minVotes; // min. quorum (ratio)
        // minAgreement is the minimum acceptable ratio of agreement for an option.
        // It's guaranteed not to win otherwise.
        uint256 minAgreement; // min. agreement threshold for options (ratio)
        uint256[] opinionScales;
        address proposalContract; // contract which stores the proposal data and executes its logic
        bytes32[] options;
        Timeline deadlines;
    }
}
