pragma solidity ^0.5.0;

import "../common/Decimal.sol";
import "../common/SafeMath.sol";

/**
 * @dev LRC implements the "least resistant consensus" paper. More detailed description can be found in Fantom's docs.
 */
library LRC {
    using SafeMath for uint256;

    struct Option {
        uint256 votes;
        uint256 agreement;
    }

    // agreementRatio is a ratio of option agreement (higher -> option is less supported)
    function agreementRatio(Option storage self) internal view returns (uint256) {
        if (self.votes == 0) {
            // avoid division by zero
            return 0;
        }
        return self.agreement.mul(Decimal.unit()).div(self.votes);
    }

    function maxAgreementScale(uint256[] storage opinionScales) internal view returns (uint256) {
        return opinionScales[opinionScales.length - 1];
    }

    function addVote(Option storage self, uint256 opinionID, uint256 weight, uint256[] storage opinionScales) internal {
        require(opinionID < opinionScales.length, "wrong opinion ID");

        uint256 scale = opinionScales[opinionID];

        self.votes = self.votes.add(weight);
        self.agreement = self.agreement.add(weight.mul(scale).div(maxAgreementScale(opinionScales)));
    }

    function removeVote(Option storage self, uint256 opinionID, uint256 weight, uint256[] storage opinionScales) internal {
        require(opinionID < opinionScales.length, "wrong opinion ID");

        uint256 scale = opinionScales[opinionID];

        self.votes = self.votes.sub(weight);
        self.agreement = self.agreement.sub(weight.mul(scale).div(maxAgreementScale(opinionScales)));
    }
}
