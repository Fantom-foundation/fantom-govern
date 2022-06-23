const { BN, ether } = require('@openzeppelin/test-helpers');

function ratio(n) {
  return ether(n);
}

module.exports = {
  PROPOSAL_TEMPLATES: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
  EMPTY_ADDRESS: '0x0000000000000000000000000000000000000000',
  CALL_TYPE: new BN('1'),
  DELEGATE_CALL_TYPE: new BN('2'),
  ratio
};
