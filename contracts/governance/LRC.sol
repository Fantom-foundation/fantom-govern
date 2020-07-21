pragma solidity ^0.5.0;

import "../common/Decimal.sol";
import "../common/SafeMath.sol";

/**
 * @dev LRC implements the "least resistant consensus" paper. More detailed description can be found in Fantom's docs.
 */
library LRC {
    using SafeMath for uint256;

    enum OptionIDs {
        VETO, // 0 = "veto"
        DISAGREE, // 1 = "disagree"
        NEUTRAL, // 2 = "neutral"
        AGREE, // 3 = "agree"
        STRONGLY_AGREE // 4 = "strongly agree"
    }

    uint256 constant opinionsNum = 5;
    uint256 constant highestVetoOpinionID = 0; // only opinion == 0 is a veto
    uint256 constant vetoExtraResistanceScale = 1;

    struct LrcOption {
        bytes32 name;
        uint256 votes;
        uint256 resistance;
        uint256 vetoVotes;
    }

    // resistanceRatio is a ratio of option resistance (higher -> option is less supported)
    function resistanceRatio(LrcOption storage self) internal view returns (uint256) {
        if (self.votes == 0) {
            return 0; // avoid division by zero
        }
        uint256 maxPossibleResistance = self.votes.mul(maxResistanceScale());
        return self.resistance.mul(Decimal.unit()).div(maxPossibleResistance);
    }

    // vetoRatio is a ratio of veto votes (higher -> option is less supported)
    function vetoRatio(LrcOption storage self) internal view returns (uint256)  {
        if (self.votes == 0) {
            return 0; // avoid division by zero
        }
        return self.vetoVotes.mul(Decimal.unit()).div(self.votes);
    }

    function getOpinionResistanceScale(uint256 opinionID) internal pure returns (uint256) {
        uint256 agree = opinionID;
        uint256 disagree = opinionsNum - 1 - agree;
        if (opinionID <= highestVetoOpinionID) {
            return disagree + vetoExtraResistanceScale;
        }
        return disagree;
    }

    function maxResistanceScale() internal pure returns (uint256) {
        return getOpinionResistanceScale(0);
    }

    function addVote(LrcOption storage self, uint256 opinionID, uint256 weight) internal {
        require(opinionID < opinionsNum, "wrong opinion ID");

        uint256 scale = getOpinionResistanceScale(opinionID);

        if (opinionID <= highestVetoOpinionID) {
            self.vetoVotes += weight;
        }
        self.votes += weight;
        self.resistance += weight * scale;
    }

    function removeVote(LrcOption storage self, uint256 opinionID, uint256 weight) internal {
        require(opinionID < opinionsNum, "wrong opinion ID");

        uint256 scale = getOpinionResistanceScale(opinionID);

        if (opinionID <= highestVetoOpinionID) {
            self.vetoVotes -= weight;
        }
        self.votes -= weight;
        self.resistance -= weight * scale;
    }
}
