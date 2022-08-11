const {
  EMPTY_ADDRESS,
  ratio,
  SFC_ADDRESS,
  PROPOSAL_TEMPLATES,
  SET_WITHDRAWAL_PERIOD_EPOCH
} = require('./constants');

async function main() {
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log('Deployer Address: ', deployerAddress);

  //   const deployedProposalTemplates = await ethers.getContractAt(
  //     'ProposalTemplates',
  //     PROPOSAL_TEMPLATES
  //   );

  //   await deployedProposalTemplates.addTemplate(
  //     15,
  //     'network',
  //     EMPTY_ADDRESS,
  //     2,
  //     ratio('0.5').toString(),
  //     ratio('0.6').toString(),
  //     [0, 2, 3, 4, 5],
  //     10000,
  //     200000,
  //     0,
  //     200
  //   );

  const NetworkParameterProposal = await ethers.getContractFactory(
    'NetworkParameterProposal'
  );

  const deployedNetworkParameterProposal = await NetworkParameterProposal.deploy(
    'network',
    'network-descr',
    [
      '0x3939000000000000000000000000000000000000000000000000000000000000',
      '0x3838000000000000000000000000000000000000000000000000000000000000',
      '0x3737000000000000000000000000000000000000000000000000000000000000'
    ],
    ratio('0.5').toString(),
    ratio('0.6').toString(),
    0,
    10000,
    10500,
    SFC_ADDRESS,
    PROPOSAL_TEMPLATES,
    SET_WITHDRAWAL_PERIOD_EPOCH,
    ['15', '17', '20'],
    2,
    [0, 2, 3, 4, 5]
  );
  await deployedNetworkParameterProposal.deployed();
  console.log(
    'NetworkParameterProposal deployed to:',
    deployedNetworkParameterProposal.address
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
