import {ethers, upgrades} from "hardhat";
import {UpgradableCounterContract} from "../typechain-types";
import {expect} from "chai";


describe("Proposals test", function () {
    it("SoftwareUpgradeProposal", async function () {
        const originalImplProxy: UpgradableCounterContract = await upgrades.deployProxy(
            await ethers.getContractFactory('UpgradableCounterContract'),
            [],
            {kind: 'uups'}
        );

        const newImplProxy: UpgradableCounterContract = await upgrades.deployProxy(
            await ethers.getContractFactory('UpgradableCounterContract'),
            [],
            {kind: 'uups'}
        );

        const newImplContract = await upgrades.erc1967.getImplementationAddress(await newImplProxy.getAddress());
        const proposalContract = await ethers.deployContract(
            "SoftwareUpgradeProposal",
            [
                "upgrade",
                "upgrade-descr",
                ethers.parseEther("0.5"),
                ethers.parseEther("0.6"),
                0,
                120,
                1200,
                originalImplProxy,
                newImplContract,
                ethers.ZeroAddress,
                "0x"
            ]
        );

        // upgrade contract
        await proposalContract.executeDelegateCall(proposalContract, 0n);
        expect(await newImplProxy.counter()).to.equal(0n);
        expect(await originalImplProxy.counter()).to.equal(1n);
    });
});