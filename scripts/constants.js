const { BN, ether } = require('@openzeppelin/test-helpers');

function ratio(n) {
  return ether(n);
}

module.exports = {
  PROPOSAL_TEMPLATES: '0xb09012a5C48840d9BCb94ab127263eB603325D50',
  SFC_ADDRESS: '0xA87c1a650D8aCEfcf017b3Ef480ece942E1BF02b',
  EMPTY_ADDRESS: '0x0000000000000000000000000000000000000000',
  GOVERNANCE: '0xdCFFfcB46Bb241DE8EED0a70329348000f5f03c7',
  ratio
};
