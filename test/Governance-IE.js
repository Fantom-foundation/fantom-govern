const {
  BN,
  ether,
  expectRevert,
  time,
  balance
} = require('@openzeppelin/test-helpers');

const { expect, assert } = require('chai');

const Governance = artifacts.require('UnitTestGovernance');
const ProposalTemplates = artifacts.require('ProposalTemplates');
const UnitTestGovernable = artifacts.require('UnitTestGovernable');
const PlainTextProposal = artifacts.require('PlainTextProposal');
const ExplicitProposal = artifacts.require('ExplicitProposal');
const ExecLoggingProposal = artifacts.require('ExecLoggingProposal');
const AlteredPlainTextProposal = artifacts.require('AlteredPlainTextProposal');
const BytecodeMatcher = artifacts.require('BytecodeMatcher');
const OwnableVerifier = artifacts.require('OwnableVerifier');

const NonExecutableType = new BN('0');
const CallType = new BN('1');
const DelegatecallType = new BN('2');

function ratio(n) {
  return ether(n);
}

const emptyAddr = '0x0000000000000000000000000000000000000000';

const { evm, exceptions } = require('./test-utils');
const { toNumber } = require('lodash');

contract('Governance test', async ([defaultAcc]) => {
  beforeEach(async () => {
    this.govable = await UnitTestGovernable.new();
    this.verifier = await ProposalTemplates.new();
    this.verifier.initialize();
    this.gov = await Governance.new();
    this.gov.initialize(this.govable.address, this.verifier.address);
    this.proposalFee = await this.gov.proposalFee();
    await evm.mine();
  });

  it('checking creation of a plaintext proposal', async () => {
    const pType = new BN(1);
    const examplePlaintext = await PlainTextProposal.new(
      'example',
      'example-descr',
      [],
      0,
      0,
      0,
      0,
      0,
      emptyAddr
    );
    const plaintextBytecodeVerifier = await BytecodeMatcher.new();
    await plaintextBytecodeVerifier.initialize(examplePlaintext.address);
    this.verifier.addTemplate(
      pType,
      'plaintext',
      plaintextBytecodeVerifier.address,
      NonExecutableType,
      ratio('0.4'),
      ratio('0.6'),
      [0, 1, 2, 3, 4],
      120,
      1200,
      0,
      60
    );

    const emptyOptions = await PlainTextProposal.new(
      'plaintext',
      'plaintext-descr',
      [],
      ratio('0.5'),
      ratio('0.6'),
      30,
      121,
      1199,
      this.verifier.address
    );
    const pType2 = await emptyOptions.pType();
    console.log(pType2.toString());

    const present = await this.verifier.exists(pType2);
    console.log('present: ', present);
  });
});
