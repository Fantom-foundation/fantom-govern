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

    struct Opinion {
        bytes32 name;
        uint256 totalVotes;
    }

    struct LrcOption {
        bytes32 name;
        uint256 arc;
        uint256 dw;
        Opinion[optionsNum] opinions;
        uint256 resistance;
        uint256 totalVotes;
        uint256 maxPossibleVotes;
    }

    struct LRCChoice {
        bytes32[] choices;
        uint256 weight;
    }

    function recalculate(LrcOption storage self) public {
        calculateARC(self);
        calculateDW(self);
    }

    function calculateARC(LrcOption storage self) public {
        uint256 maxPossibleResistance = self.totalVotes.mul(maxResistanceScale());
        self.arc = self.resistance.mul(Decimal.unit()).div(maxPossibleResistance);
    }

    function calculateDW(LrcOption storage self) public {
        uint256 totalVeto;
        for (uint256 i = lowestVetoIdx; i < optionsNum; i++) {
            totalVeto = totalVeto.add(self.opinions[i].totalVotes);
        }

        self.dw = totalVeto.mul(Decimal.unit()).div(self.totalVotes);
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
        self.opinions[opinionId].totalVotes += weight;

        uint256 scale = getOpinionResistanceScale(opinionId);

        self.totalVotes += weight;
        self.resistance += weight * scale;
    }

    function removeVote(LrcOption storage self, uint256 opinionId, uint256 weight) public {
        require(opinionId < optionsNum, "wrong opinion id");
        self.opinions[opinionId].totalVotes -= weight;

        uint256 scale = getOpinionResistanceScale(opinionId);

        self.totalVotes -= weight;
        self.resistance -= weight * scale;
    }
}
