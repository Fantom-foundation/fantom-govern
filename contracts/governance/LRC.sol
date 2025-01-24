// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../common/Decimal.sol";


/// @dev LRC implements the "least resistant consensus" paper. More detailed description can be found in Sonic's docs.
library LRC {
    // Option represents a single option in the proposal
    struct Option {
        uint256 votes;
        uint256 agreement;
    }

    /// @dev ratio of option agreement (higher -> option is less supported)
    /// @param self The option for which the agreement will be calculated
    /// @return agreement ratio
    function agreementRatio(Option storage self) internal view returns (uint256) {
        if (self.votes == 0) {
            // avoid division by zero
            return 0;
        }
        return self.agreement * Decimal.unit() / self.votes;
    }

    /// @dev maxAgreementScale returns the maximum agreement scale
    /// @param opinionScales The opinion scales
    /// @return max agreement scale
    function maxAgreementScale(uint256[] storage opinionScales) internal view returns (uint256) {
        return opinionScales[opinionScales.length - 1];
    }

    /// @dev addVote adds a vote to the option
    /// @param self The option to which the vote will be added
    /// @param opinionID The voted opinion ID
    /// @param weight The weight of the vote
    /// @param opinionScales The opinion scales
    function addVote(Option storage self, uint256 opinionID, uint256 weight, uint256[] storage opinionScales) internal {
        require(opinionID < opinionScales.length, "wrong opinion ID");

        uint256 scale = opinionScales[opinionID];

        self.votes = self.votes + weight;
        self.agreement = self.agreement + weight * scale / maxAgreementScale(opinionScales);
    }

    /// @dev removeVote removes a vote from the option
    /// @param self The option from which the vote will be removed
    /// @param opinionID The voted opinion ID
    /// @param weight The weight of the vote
    /// @param opinionScales The opinion scales
    function removeVote(Option storage self, uint256 opinionID, uint256 weight, uint256[] storage opinionScales) internal {
        require(opinionID < opinionScales.length, "wrong opinion ID");

        uint256 scale = opinionScales[opinionID];

        self.votes = self.votes - weight;
        self.agreement = self.agreement - weight * scale / maxAgreementScale(opinionScales);
    }
}
