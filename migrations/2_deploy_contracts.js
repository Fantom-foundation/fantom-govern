const LRC = artifacts.require("LRC");
const Governance = artifacts.require("Governance");
const TestStakers = artifacts.require("TestStakers");
const UnitTestProposal = artifacts.require("UnitTestProposal");
const UpgradeabilityProxy = artifacts.require('UpgradeabilityProxy');
const ProposalFactory = artifacts.require('ProposalFactory');
const DummySoftwareContract = artifacts.require('DummySoftwareContract');

module.exports = async(deployer, network) => {
  await deployer.deploy(TestStakers);
  await deployer.deploy(LRC);
  await deployer.link(LRC, Governance);
  await deployer.deploy(UpgradeabilityProxy);
  await deployer.deploy(ProposalFactory, UpgradeabilityProxy.address);
  await deployer.deploy(Governance, TestStakers.address, ProposalFactory.address);
  await deployer.deploy(DummySoftwareContract);
  // await deployer.deploy(UnitTestProposal);
};
