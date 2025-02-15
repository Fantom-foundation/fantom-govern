import {ethers} from "hardhat";
import {loadFixture, time} from "@nomicfoundation/hardhat-network-helpers";
import {expect} from "chai";
import {DelegateCallType, initConsts, NonExecutableType} from "./utils";


const proposalFactoryFixture = async function () {
    const [acc1, acc2] = await ethers.getSigners();
    const verifier = await ethers.deployContract("ProposalTemplates")
    await verifier.initialize(acc1);
    const gov = await ethers.deployContract("Governance");
    // Governable and VoteBook are not necessary for this test
    await gov.initialize(ethers.ZeroAddress, await verifier.getAddress(), ethers.ZeroAddress)
    return {gov, verifier, acc1, acc2}
}

describe("ProposalFactory test", function () {
    beforeEach("create vote", async function () {
        Object.assign(this, await loadFixture(proposalFactoryFixture));
    });

    it("NetworkParameterProposalFactory", async function () {
        await this.verifier.addTemplate(
            6003,
            "NetworkParameterProposal",
            ethers.ZeroAddress,
            DelegateCallType,
            ethers.parseEther("0.0"),
            ethers.parseEther("0.0"),
            [0, 1, 2, 3, 4],
            0,
            100000000,
            0,
            100000000
        );

        // Deploy factory with necessary constants contract
        const consts = await initConsts(this.acc1);
        const factory = await ethers.deployContract(
            "NetworkParameterProposalFactory", [
            await this.gov.getAddress(),
            await consts.getAddress()
        ]);
        // Create proposal
        await factory.create("description", 1, [ethers.parseEther("1")], 3, 4, 5, 6, 7, {value: await this.gov.proposalFee()});
        // Check its parameters
        const proposalParams = await this.gov.proposalParams(await this.gov.lastProposalID())
        expect(proposalParams.pType).to.be.equal(6003);
        expect(proposalParams.executable).to.be.equal(DelegateCallType);
        expect(proposalParams.options.length).to.equal(1);
        expect(proposalParams.minVotes).to.be.equal(3);
        expect(proposalParams.minAgreement).to.be.equal(4);
        const now = await time.latest();
        const start = now + 5;
        expect(proposalParams.votingStartTime).to.be.equal(now+5);
        expect(proposalParams.votingMinEndTime).to.be.equal(start+6);
        expect(proposalParams.votingMaxEndTime).to.be.equal(start+7);
    });

    it("PlainTextProposalFactory", async function () {
        await this.verifier.addTemplate(
            1,
            "PlainTextProposal",
            ethers.ZeroAddress,
            NonExecutableType,
            ethers.parseEther("0.0"),
            ethers.parseEther("0.0"),
            [0, 1, 2, 3, 4],
            0,
            100000000,
            0,
            100000000
        );
        // Deploy factory
        const factory = await ethers.deployContract("PlainTextProposalFactory", [await this.gov.getAddress()]);
        // Create proposal
        await factory.create("name", "description", [ethers.encodeBytes32String("opt")], 3, 4, 5, 6, 7, {value: await this.gov.proposalFee()});
        // Check its parameters
        const proposalParams = await this.gov.proposalParams(await this.gov.lastProposalID())
        expect(proposalParams.pType).to.be.equal(1);
        expect(proposalParams.executable).to.be.equal(NonExecutableType);
        expect(proposalParams.options.length).to.equal(1);
        expect(proposalParams.minVotes).to.be.equal(3);
        expect(proposalParams.minAgreement).to.be.equal(4);
        const now = await time.latest();
        const start = now + 5;
        expect(proposalParams.votingStartTime).to.be.equal(now+5);
        expect(proposalParams.votingMinEndTime).to.be.equal(start+6);
        expect(proposalParams.votingMaxEndTime).to.be.equal(start+7);
    });

    it("SlashingRefundProposalFactory", async function () {
        await this.verifier.addTemplate(
            5003,
            "SlashingRefundProposal",
            ethers.ZeroAddress,
            DelegateCallType,
            ethers.parseEther("0.0"),
            ethers.parseEther("0.0"),
            [0, 1, 2, 3, 4],
            0,
            100000000,
            0,
            100000000
        );
        // Deploy factory with necessary SFC contract
        const sfc = await ethers.deployContract("UnitTestSFC");
        // Add validator and slash them
        await sfc.addValidator(1, 0, this.acc1);
        await sfc.slash(1);
        const factory = await ethers.deployContract(
            "SlashingRefundProposalFactory", [
            await this.gov.getAddress(),
            await sfc.getAddress()
        ]);
        // Create proposal
        await factory.create(1, "description", 3, 4, 5, 6, 7, {value: await this.gov.proposalFee()});
        // Check its parameters
        const proposalParams = await this.gov.proposalParams(await this.gov.lastProposalID())
        expect(proposalParams.pType).to.be.equal(5003);
        expect(proposalParams.executable).to.be.equal(DelegateCallType);
        expect(proposalParams.options.length).to.equal(6); // Options are static for SlashingRefundProposal
        expect(proposalParams.minVotes).to.be.equal(3);
        expect(proposalParams.minAgreement).to.be.equal(4);
        const now = await time.latest();
        const start = now + 5;
        expect(proposalParams.votingStartTime).to.be.equal(now+5);
        expect(proposalParams.votingMinEndTime).to.be.equal(start+6);
        expect(proposalParams.votingMaxEndTime).to.be.equal(start+7);
    });
})

