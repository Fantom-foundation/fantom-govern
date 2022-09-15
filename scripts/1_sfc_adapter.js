async function main() {
  const SFCToGovernable = await ethers.getContractFactory('SFCToGovernable');

  const deployedSFCToGovernable = await SFCToGovernable.deploy();
  await deployedSFCToGovernable.deployed();
  console.log('SFCToGovernable deployed to:', deployedSFCToGovernable.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
