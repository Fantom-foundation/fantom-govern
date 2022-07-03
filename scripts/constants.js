const { BN, ether } = require('@openzeppelin/test-helpers');

function ratio(n) {
  return ether(n);
}

module.exports = {
  PROPOSAL_TEMPLATES: '0xb09012a5C48840d9BCb94ab127263eB603325D50',
  SFC_ADDRESS: '0xA87c1a650D8aCEfcf017b3Ef480ece942E1BF02b',
  EMPTY_ADDRESS: '0x0000000000000000000000000000000000000000',
  SET_MAX_DELEGATION: 'setMaxDelegation(uint256)',
  SET_WITHDRAWAL_PERIOD_EPOCH: 'setWithdrawalPeriodEpoch(uint256)',
  ratio
};
