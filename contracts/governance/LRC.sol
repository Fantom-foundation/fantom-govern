pragma solidity ^0.5.0;

import "../common/Decimal.sol";
import "../common/SafeMath.sol";

/**
 * @dev LRC implements the "least resistant consensus" paper. More detailed description can be found in Fantom's docs.
 */
library LRC {
    using SafeMath for uint256;

    //
    enum OptionValue {
        STRONGLY_AGREE, // "strongly agree"
        AGREE, // "agree"
        NEUTRAL, // "neutral"
        DISAGREE, // "disagree"
        VETO // "veto"
    }

    uint256 constant optionsNum = 5;
    uint256 constant lowestVetoIdx = optionsNum - 1; // only last opinion is a veto
    uint256 constant vetoExtraResistanceScale = 1;

    struct LrcOption {
        bytes32 name;
        uint256 resistance;
        uint256 vetoVotes;
        uint256 totalVotes;
    }

    // resistanceRatio is a ratio of option resistance (higher -> option is less supported)
    function resistanceRatio(LrcOption storage self) public view returns(uint256) {
        uint256 maxPossibleResistance = self.totalVotes.mul(maxResistanceScale());
        return self.resistance.mul(Decimal.unit()).div(maxPossibleResistance);
    }

    // vetoRatio is a ratio of veto votes (higher -> option is less supported)
    function vetoRatio(LrcOption storage self) public view returns(uint256)  {
        return self.vetoVotes.mul(Decimal.unit()).div(self.totalVotes);
    }

    function getOpinionResistanceScale(uint256 opinionId) public pure returns(uint256) {
        if (opinionId >= lowestVetoIdx) {
            return opinionId + vetoExtraResistanceScale;
        }
        return opinionId;
    }

    function maxResistanceScale() public pure returns(uint256) {
        return getOpinionResistanceScale(optionsNum - 1);
    }

    function addVote(LrcOption storage self, uint256 opinionId, uint256 weight) public {
        require(opinionId < optionsNum, "wrong opinion id");

        uint256 scale = getOpinionResistanceScale(opinionId);

        if (opinionId >= lowestVetoIdx) {
            self.vetoVotes += weight;
        }
        self.totalVotes += weight;
        self.resistance += weight * scale;
    }

    function removeVote(LrcOption storage self, uint256 opinionId, uint256 weight) public {
        require(opinionId < optionsNum, "wrong opinion id");

        uint256 scale = getOpinionResistanceScale(opinionId);

        if (opinionId >= lowestVetoIdx) {
            self.vetoVotes -= weight;
        }
        self.totalVotes -= weight;
        self.resistance -= weight * scale;
    }
}
