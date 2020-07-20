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

    uint256 constant OptionsNum = 5;
    uint256 constant levelOfDesignation = OptionsNum - 1; //
    uint256 constant maxScale = 5;
    // mapping(uint256 => uint256) scales;

    struct Opinion {
        bytes32 name;
        uint256 totalVotes;
    }

    struct LrcOption {
        bytes32 name;
        uint256 arc;
        uint256 dw;
        Opinion[OptionsNum] opinions;
        uint256 resistance;
        uint256 totalVotes;
        uint256 maxPossibleVotes;
    }

    struct LRCChoice {
        bytes32[] choices;
        uint256 weight;
    }

    // function addScale(uint256 scale, uint256 idx) public {
    //    scales[idx] = scale;
    // }

    function recalculate(LrcOption storage self) public {
        calculateARC(self);
        calculateDW(self);
    }

    function calculateARC(LrcOption storage self) public {
        uint256 maxPossibleResistance = self.totalVotes * maxScale;
        uint256 rebasedActualResistance = self.resistance * Decimal.unit();
        self.arc = rebasedActualResistance / maxPossibleResistance;
    }

    function calculateDW(LrcOption storage self) public {
        uint256 totalDesignation;
        for (uint256 i = levelOfDesignation; i < OptionsNum; i++) {
            totalDesignation += self.opinions[i].totalVotes;
        }

        uint256 designationRebased = totalDesignation * Decimal.unit();
        self.dw = designationRebased / self.totalVotes;
    }

    function calculateRawCount(LrcOption storage self) public {

    }

    function addVote(LrcOption storage self, uint256 opinionId, uint256 weight) public {
        require(opinionId < OptionsNum, "wrong opinion id");
        self.opinions[opinionId].totalVotes += weight;

        uint256 scale;
        if (opinionId == OptionsNum - 1) {
            scale = OptionsNum;
        } else {
            scale = opinionId;
        }

        self.totalVotes += weight;
        self.resistance += weight * scale;
    }

    function removeVote(LrcOption storage self, uint256 opinionId, uint256 weight) public {
        require(opinionId < OptionsNum, "wrong opinion id");
        self.opinions[opinionId].totalVotes -= weight;

        uint256 scale;
        if (opinionId == OptionsNum - 1) {
            scale = OptionsNum;
        }
        scale = opinionId;

        self.totalVotes -= weight;
        self.resistance -= weight * scale;
    }
}
