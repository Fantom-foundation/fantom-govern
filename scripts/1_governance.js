async function main() {
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log('Deployer Address: ', deployerAddress);

  const Governance = await ethers.getContractFactory('Governance');
  const UnitTestGovernable = await ethers.getContractFactory(
    'UnitTestGovernable'
  );
  const ProposalTemplates = await ethers.getContractFactory(
    'ProposalTemplates'
  );

  const deployedGovernable = await UnitTestGovernable.deploy();
  await deployedGovernable.deployed();
  console.log('Governable deployed to:', deployedGovernable.address);

  const deployedGovernance = await Governance.deploy();
  await deployedGovernance.deployed();
  console.log('Governance deployed to:', deployedGovernance.address);

  const deployedProposalTemplates = await ProposalTemplates.deploy();
  await deployedProposalTemplates.deployed();
  console.log(
    'ProposalTemplates deployed to:',
    deployedProposalTemplates.address
  );

  const proposalTemplate = await ethers.getContractAt(
    'ProposalTemplates',
    deployedProposalTemplates.address
  );

  await proposalTemplate.initialize();

  const governance = await ethers.getContractAt(
    'Governance',
    deployedGovernance.address
  );

  await governance.initialize(
    deployedGovernable.address,
    deployedProposalTemplates.address
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
