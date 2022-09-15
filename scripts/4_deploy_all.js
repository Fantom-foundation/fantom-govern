const { EMPTY_ADDRESS, ratio } = require('./constants');

async function main() {
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log('Deployer Address: ', deployerAddress);

  const Governance = await ethers.getContractFactory('UnitTestGovernance');
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

  const governance = await ethers.getContractAt(
    'Governance',
    deployedGovernance.address
  );

  await governance.initialize(
    deployedGovernable.address,
    deployedProposalTemplates.address
  );

  await deployedProposalTemplates.initialize();

  const BytecodeMatcher = await ethers.getContractFactory('BytecodeMatcher');
  const PlainTextProposal = await ethers.getContractFactory(
    'PlainTextProposal'
  );

  const deployedBytecodeMatcher = await BytecodeMatcher.deploy();
  await deployedBytecodeMatcher.deployed();
  console.log('BytecodeMatcher deployed to:', deployedBytecodeMatcher.address);

  const bytecodeMatcher = await ethers.getContractAt(
    'BytecodeMatcher',
    deployedBytecodeMatcher.address
  );

  const deployedPlainTextProposal = await PlainTextProposal.deploy(
    'example',
    'example-descr',
    [],
    0,
    0,
    0,
    0,
    0,
    EMPTY_ADDRESS
  );
  await deployedPlainTextProposal.deployed();
  console.log(
    'PlainTextProposal deployed to:',
    deployedPlainTextProposal.address
  );

  await bytecodeMatcher.initialize(deployedPlainTextProposal.address);

  await deployedProposalTemplates.addTemplate(
    1,
    'plaintext',
    deployedPlainTextProposal.address,
    0,
    ratio('0.4').toString(),
    ratio('0.6').toString(),
    [0, 1, 2, 3, 4],
    120,
    1200,
    0,
    60
  );

  const NetworkParameterProposal = await ethers.getContractFactory(
    'NetworkParameterProposal'
  );

  await deployedProposalTemplates.addTemplate(
    15,
    'network',
    EMPTY_ADDRESS,
    2,
    ratio('0.5').toString(),
    ratio('0.6').toString(),
    [0, 2, 3, 4, 5],
    120,
    1200,
    0,
    200
  );

  const deployedNetworkParameterProposal = await NetworkParameterProposal.deploy(
    'network',
    'network-descr',
    ['0x3939000000000000000000000000000000000000000000000000000000000000'],
    ratio('0.5').toString(), //50000000000000000, //0.05
    ratio('0.6').toString(), //60000000000000000, //0.06
    0,
    180,
    240,
    '0xA87c1a650D8aCEfcf017b3Ef480ece942E1BF02b',
    deployedProposalTemplates.address, //EMPTY_ADDRESS, //'0x8f61361b5dA87dF955B6eFcFE6f637a789817165',
    'setMaxDelegation(uint256)',
    ['15'], // [15000000000000000000]
    2,
    [0, 2, 3, 4, 5]
  );
  await deployedNetworkParameterProposal.deployed();
  console.log(
    'NetworkParameterProposal deployed to:',
    deployedNetworkParameterProposal.address
  );

  const proposalFee = await deployedGovernance.proposalFee();
  console.log(proposalFee.toString());
  await deployedGovernance.createProposal(
    deployedNetworkParameterProposal.address,
    { value: proposalFee.toString() }
  );

  await deployedGovernable.stake(deployerAddress, 5);
  await deployedGovernance.vote(deployerAddress, 1, [2]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
