const { EMPTY_ADDRESS } = require('../constants');

async function main() {
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

  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
