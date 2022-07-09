async function main() {
  const ProposalFactory = await ethers.getContractFactory('ProposalFactory');

  const deployedProposalFactory = await ProposalFactory.deploy();
  await deployedProposalFactory.deployed();
  console.log('ProposalFactory deployed to:', deployedProposalFactory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
