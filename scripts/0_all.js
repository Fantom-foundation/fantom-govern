const { SFC_ADDRESS } = require('./constants');

async function main() {
    const [deployer] = await ethers.getSigners();
    const deployerAddress = await deployer.getAddress();
    console.log('Deployer Address: ', deployerAddress);

    const SFCToGovernable = await ethers.getContractFactory('SFCToGovernable');

    const deployedSFCToGovernable = await SFCToGovernable.deploy();
    await deployedSFCToGovernable.deployed();
    console.log('SFCToGovernable deployed to:', deployedSFCToGovernable.address);

    const Governance = await ethers.getContractFactory('UnitTestGovernance'); //only for testing

    const ProposalTemplates = await ethers.getContractFactory('ProposalTemplates');

    const deployedProposalTemplates = await ProposalTemplates.deploy();
    await deployedProposalTemplates.deployed();
    console.log('ProposalTemplates deployed to:', deployedProposalTemplates.address);
    console.log('Initialize ProposalTempalte...');
    await deployedProposalTemplates.initialize();

    const deployedGovernance = await Governance.deploy();
    await deployedGovernance.deployed();
    console.log('Governance deployed to:', deployedGovernance.address);
    console.log('Initialize Governance...');
    await deployedGovernance.initialize(deployedSFCToGovernable.address, deployedProposalTemplates.address);

    const ProposalFactory = await ethers.getContractFactory('ProposalFactory');

    const deployedProposalFactory = await ProposalFactory.deploy(deployedGovernance.address, SFC_ADDRESS);
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