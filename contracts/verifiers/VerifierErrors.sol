// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Proposal} from "../governance/Proposal.sol";

interface VerifierErrors {
    error UnknownTemplate(uint256 pType);
    error ExecutableTypeMismatch(Proposal.ExecType got, Proposal.ExecType want);
    error MinVotesTooSmall(uint256 got, uint256 min);
    error MinVotesTooLarge(uint256 got, uint256 max);
    error MinAgreementTooSmall(uint256 got, uint256 min);
    error MinAgreementTooLarge(uint256 got, uint256 max);
    error OpinionScalesLengthMismatch(uint256 got, uint256 want);
    error OpinionScalesMismatch(uint256 got, uint256 want, uint256 idx);
    error StartIsInThePast();
    error StartIsAfterMinEnd(uint256 start, uint256 minEnd);
    error MinEndIsAfterMaxEnd(uint256 minEnd, uint256 maxEnd);
    error ParametersVerificationFailed(string message);
    error MinDurationIsTooShort(uint256 got, uint256 min);
    error MaxDurationIsTooLong(uint256 got, uint256 max);
    error StartDelayIsTooSmall(uint256 got, uint256 min);
    error StartDelayIsTooLarge(uint256 got, uint256 max);
    error AppropriateFactoryNotUsed();
}
