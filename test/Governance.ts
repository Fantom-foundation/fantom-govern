import {BigNumberish} from "ethers";

import {expect} from "chai";
import {ethers} from "hardhat";
import {loadFixture, time} from "@nomicfoundation/hardhat-network-helpers";
import {ExecLoggingProposal, Governance, ProposalTemplates} from "../typechain-types"
import type {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/src/signers";
import {CallType, DelegateCallType, initConsts, NonExecutableType} from "./utils";
import {min} from "hardhat/internal/util/bigint";


const scales = [0, 2, 3, 4, 5];

const ProposalStatus = {
    INITIAL: 0n,
    RESOLVED: 1n,
    FAILED: 2n,
    CANCELED: 3n,
    EXECUTION_EXPIRED: 4n,
}

const governanceFixture = async function () {
    const [defaultAcc, otherAcc, firstVoterAcc, secondVoterAcc, delegatorAcc] = await ethers.getSigners();
    const sfc = await ethers.deployContract("UnitTestSFC");
    await sfc.addValidator(1, 0, defaultAcc)
    await sfc.addValidator(2, 0, firstVoterAcc)
    const govable = await ethers.deployContract("SFCGovernableAdapter", [await sfc.getAddress()]);
    const verifier = await ethers.deployContract("ProposalTemplates")
    const verifierAddress = await verifier.getAddress();
    const votebook = await ethers.deployContract("VotesBookKeeper");
    const gov = await ethers.deployContract("Governance");
    await verifier.initialize(defaultAcc.getAddress());
    await votebook.initialize(defaultAcc.getAddress(), gov.getAddress(), 1000);
    await gov.initialize(govable.getAddress(), verifierAddress, votebook.getAddress());
    const proposalFee = await gov.proposalFee();

    return {
        sfc,
        govable,
        verifier,
        verifierAddress,
        votebook,
        gov,
        defaultAcc,
        otherAcc,
        firstVoterAcc,
        secondVoterAcc,
        delegatorAcc,
        proposalFee,
    }
}

describe("Governance test", function () {
    beforeEach(async function (){
        Object.assign(this, await loadFixture(governanceFixture));
    });
    it("checking deployment of a plaintext proposal contract", async function () {
        await this.verifier.addTemplate(1, "plaintext", ethers.ZeroAddress, NonExecutableType, ethers.parseEther("0.4"), ethers.parseEther("0.6"), [0, 1, 2, 3, 4], 120, 1200, 0, 60);
        const option = ethers.encodeBytes32String("opt");
        await expect(ethers.deployContract("PlainTextProposal", ["plaintext", "plaintext-descr", [option], ethers.parseEther("0.4"), ethers.parseEther("0.6"), 0, 120, 1201, this.verifierAddress]))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MaxDurationIsTooLong"
            )
            .withArgs(1201, 1200);
        await expect(ethers.deployContract("PlainTextProposal", ["plaintext", "plaintext-descr", [option], ethers.parseEther("0.4"), ethers.parseEther("0.6"), 0, 119, 1201, this.verifierAddress]))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinDurationIsTooShort"
            )
            .withArgs(119, 120);
        await expect(ethers.deployContract("PlainTextProposal", ["plaintext", "plaintext-descr", [option], ethers.parseEther("0.4"), ethers.parseEther("0.6"), 61, 119, 1201, this.verifierAddress]))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinDurationIsTooShort"
            )
            .withArgs(119, 120);
        await expect(ethers.deployContract("PlainTextProposal", ["plaintext", "plaintext-descr", [option], ethers.parseEther("0.4"), ethers.parseEther("0.6"), 0, 501, 500, this.verifierAddress]))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinEndIsAfterMaxEnd"
            )
        await expect(ethers.deployContract("PlainTextProposal", ["plaintext", "plaintext-descr", [option], ethers.parseEther("0.399"), ethers.parseEther("0.6"), 0, 501, 500, this.verifierAddress]))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinVotesTooSmall"
            )
            .withArgs(ethers.parseEther("0.399"),ethers.parseEther("0.4"));
        await expect(ethers.deployContract("PlainTextProposal", ["plaintext", "plaintext-descr", [option], ethers.parseEther("1.01"), ethers.parseEther("0.6"), 0, 501, 500, this.verifierAddress]))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinVotesTooLarge"
            )
            .withArgs(ethers.parseEther("1.01"), ethers.parseEther("1"));
        await expect(ethers.deployContract("PlainTextProposal", ["plaintext", "plaintext-descr", [option], ethers.parseEther("0.4"), ethers.parseEther("0.599"), 60, 120, 1200, this.verifierAddress]))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinAgreementTooSmall"
            )
            .withArgs(ethers.parseEther("0.599"),ethers.parseEther("0.6"));
        await expect(ethers.deployContract("PlainTextProposal", ["plaintext", "plaintext-descr", [option], ethers.parseEther("0.4"), ethers.parseEther("1.01"), 60, 120, 1200, this.verifierAddress]))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinAgreementTooLarge"
            )
            .withArgs(ethers.parseEther("1.01"), ethers.parseEther("1"));
    });

    it("checking creation of a plaintext proposal", async function () {
        const pType = 1n;
        const now = await time.latest();
        await this.verifier.addTemplate(pType, "plaintext", ethers.ZeroAddress, NonExecutableType, ethers.parseEther("0.4"), ethers.parseEther("0.6"), [0, 1, 2, 3, 4], 120, 1200, 0, 60);
        const option = ethers.encodeBytes32String("opt");
        const emptyOptions = await ethers.deployContract("PlainTextProposal", ["plaintext","plaintext-descr", [], ethers.parseEther("0.5"), ethers.parseEther("0.6"), 30, 121, 1199, this.verifierAddress]);
        const tooManyOptions = await ethers.deployContract("PlainTextProposal", ["plaintext","plaintext-descr", [option, option, option, option, option, option, option, option, option, option, option], ethers.parseEther("0.5"), ethers.parseEther("0.6"), 30, 121, 1199, this.verifierAddress]);
        const wrongVotes = await ethers.deployContract("PlainTextProposal", ["plaintext","plaintext-descr", [option], ethers.parseEther("0.3"), ethers.parseEther("0.6"), 30, 121, 1199, ethers.ZeroAddress]);
        const manyOptions = await ethers.deployContract("PlainTextProposal", ["plaintext","plaintext-descr", [option, option, option, option, option, option, option, option, option, option], ethers.parseEther("0.5"), ethers.parseEther("0.6"), 30, 121, 1199, this.verifierAddress]);
        const oneOption = await ethers.deployContract("PlainTextProposal", ["plaintext","plaintext-descr", [option], ethers.parseEther("0.51"), ethers.parseEther("0.6"), 30, 122, 1198, this.verifierAddress]);

        await expect(this.gov.createProposal(emptyOptions.getAddress(), {value: this.proposalFee})).to.be.revertedWith("proposal options are empty");
        await expect(this.gov.createProposal(tooManyOptions.getAddress(), {value: this.proposalFee})).to.be.revertedWith("too many options");
        await expect(this.gov.createProposal(wrongVotes.getAddress(), {value: this.proposalFee}))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinVotesTooSmall"
            )
            .withArgs(ethers.parseEther("0.3"), ethers.parseEther("0.4"));
        await expect(this.gov.createProposal(manyOptions.getAddress())).to.be.revertedWith("paid proposal fee is wrong");
        await expect(this.gov.createProposal(manyOptions.getAddress(), {value: this.proposalFee+1n})).to.be.revertedWith("paid proposal fee is wrong");
        await this.gov.createProposal(manyOptions.getAddress(), {value: this.proposalFee});
        await this.gov.createProposal(oneOption.getAddress(), {value: this.proposalFee});

        const infoManyOptions = await this.gov.proposalParams(1);
        expect(infoManyOptions.pType).to.be.equal(pType);
        expect(infoManyOptions.executable).to.be.equal(NonExecutableType);
        expect(infoManyOptions.minVotes).to.be.equal(ethers.parseEther("0.5"));
        expect(infoManyOptions.proposalContract).to.equal(await manyOptions.getAddress());
        expect(infoManyOptions.options.length).to.equal(10);
        expect(infoManyOptions.options[0]).to.equal("0x6f70740000000000000000000000000000000000000000000000000000000000");
        expect(infoManyOptions.votingStartTime).to.be.least(now);
        expect(infoManyOptions.votingMinEndTime).to.be.equal(infoManyOptions.votingStartTime+121n);
        expect(infoManyOptions.votingMaxEndTime).to.be.equal(infoManyOptions.votingStartTime+1199n);
        const infoOneOption = await this.gov.proposalParams(2);
        expect(infoOneOption.pType).to.be.equal(pType);
        expect(infoOneOption.executable).to.be.equal(NonExecutableType);
        expect(infoOneOption.minVotes).to.be.equal(ethers.parseEther("0.51"));
        expect(infoOneOption.proposalContract).to.equal(await oneOption.getAddress());
        expect(infoOneOption.options.length).to.equal(1);
        expect(infoOneOption.votingStartTime).to.be.least(now);
        expect(infoOneOption.votingMinEndTime).to.be.equal(infoOneOption.votingStartTime+122n);
        expect(infoOneOption.votingMaxEndTime).to.be.equal(infoOneOption.votingStartTime+1198n);
    });

    it("checking proposal verification with explicit timestamps and opinions", async function () {
        // check code which can be checked only by explicitly setting timestamps and opinions
        const pType = 999; // non-standard proposal type
        await this.verifier.addTemplate(pType, "custom", ethers.ZeroAddress, DelegateCallType, ethers.parseEther("0.4"), ethers.parseEther("0.6"), scales, 1000, 10000, 400, 2000);
        const now = await time.latest();
        const start = now + 500;
        const minEnd = start + 1000;
        const maxEnd = minEnd + 1000;

        const proposal = await ethers.deployContract("ExplicitProposal");
        await proposal.setType(pType);
        await proposal.setMinVotes(ethers.parseEther("0.4"));
        await proposal.setMinAgreement(ethers.parseEther("0.6"));
        await proposal.setOpinionScales(scales);
        await proposal.setVotingStartTime(start);
        await proposal.setVotingMinEndTime(minEnd);
        await proposal.setVotingMaxEndTime(maxEnd);
        await proposal.setExecutable(DelegateCallType);
        await proposal.verifyProposalParams(this.verifierAddress);

        await proposal.setVotingStartTime(now-10); // starts in past
        await expect(proposal.verifyProposalParams(this.verifierAddress))
            .to.be.revertedWithCustomError(
                this.verifier,
                "StartIsInThePast"
            );
        await proposal.setVotingStartTime(start);

        await proposal.setVotingMinEndTime(start-1); // may end before the start
        await expect(proposal.verifyProposalParams(this.verifierAddress))
            .to.be.revertedWithCustomError(
                this.verifier,
                "StartIsAfterMinEnd"
            )
        await proposal.setVotingMinEndTime(minEnd);

        await proposal.setVotingMaxEndTime(start-1); // must end before the start
        await expect(proposal.verifyProposalParams(this.verifierAddress))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinEndIsAfterMaxEnd"
            )
        await proposal.setVotingMaxEndTime(maxEnd);

        await proposal.setVotingMaxEndTime(minEnd-1); // min > max
        await expect(proposal.verifyProposalParams(this.verifierAddress))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinEndIsAfterMaxEnd"
            )
        await proposal.setVotingMaxEndTime(maxEnd);

        await proposal.setType(pType - 1); // wrong type
        await expect(proposal.verifyProposalParams(this.verifierAddress))
            .to.be.revertedWithCustomError(
                this.verifier,
                "UnknownTemplate"
            )
            .withArgs(pType - 1)
        await proposal.setType(pType);

        await proposal.setOpinionScales([]); // wrong scales
        await expect(proposal.verifyProposalParams(this.verifierAddress))
            .to.be.revertedWithCustomError(
                this.verifier,
                "OpinionScalesLengthMismatch"
            )
            .withArgs(0, 5)
        await proposal.setOpinionScales([1]); // wrong scales
        await expect(proposal.verifyProposalParams(this.verifierAddress))
            .to.be.revertedWithCustomError(
                this.verifier,
                "OpinionScalesLengthMismatch"
            )
            .withArgs(1, 5)
        await proposal.setOpinionScales([1, 2, 3, 4, 5]); // wrong scales
        await expect(proposal.verifyProposalParams(this.verifierAddress))
            .to.be.revertedWithCustomError(
                this.verifier,
                "OpinionScalesMismatch"
            )
            .withArgs(1,0,0)
        await proposal.setOpinionScales(scales);

        await proposal.verifyProposalParams(this.verifierAddress)
    });



    it("checking creation and execution of network parameter proposals via proposal factory", async function () {
        const optionsNum = ethers.parseEther("1"); // use maximum number of options to test gas usage
        const choices = [4n];
        const voteEnd = 120;

        const consts = await initConsts(this.defaultAcc);
        expect((await consts.minSelfStake()).toString()).to.equals("317500000000000000");

        if (await this.verifier.exists(15) === false) {
            await this.verifier.addTemplate(6003, "NetworkParameterProposal", ethers.ZeroAddress, DelegateCallType, ethers.parseEther("0.0"), ethers.parseEther("0.0"), [0, 1, 2, 3, 4], 0, 100000000, 0, 100000000);
        }
        const updateMinSelfStake = await ethers.deployContract(
            "NetworkParameterProposal",
            [
                "Network",
                1,
                [optionsNum],
                await consts.getAddress(),
                ethers.parseEther("0.5"),
                ethers.parseEther("0.6"),
                0,
                1,
                voteEnd,
                this.verifierAddress,
            ]
        )
        // make new vote
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        await this.gov.createProposal(updateMinSelfStake.getAddress(), {value: this.proposalFee});

        const proposalIdOne = await this.gov.lastProposalID();
        await this.gov.vote(this.defaultAcc, proposalIdOne, choices);
        // Advance time by voteEnd + 1 to make sure the voting has ended
        await time.increase(voteEnd+1);
        // Execute the proposal
        await this.gov.handleTasks(0, 1);

        expect((await consts.minSelfStake()).toString()).to.equals(optionsNum);
    });

    it("checking self-vote creation", async function () {
        const optionsNum = 3;
        const choices = [0n, 3n, 4n];
        await createProposal(this.gov, this.verifier, NonExecutableType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), 60);
        const proposalID = await this.gov.lastProposalID();

        // Voting has not begun yet
        await expect(this.gov.vote(this.defaultAcc, proposalID, choices)).to.be.revertedWith("proposal voting hasn't begun");
        // Forward time to stat the voting
        await time.increase(60);
        // Voting with no stake
        await expect(this.gov.vote(this.defaultAcc, proposalID, choices)).to.be.revertedWith("zero weight");
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        // Non-existent proposal
        await expect(this.gov.vote(this.defaultAcc, proposalID+1n, choices)).to.be.revertedWith("given proposalID doesn't exist");
        // Incorrect choices
        await expect(this.gov.vote(this.defaultAcc, proposalID, [3n, 4n])).to.be.revertedWith("wrong number of choices");
        // Non-existent opinion
        await expect(this.gov.vote(this.defaultAcc, proposalID, [5n, 3n, 4n])).to.be.revertedWith("wrong opinion ID");
        await this.gov.vote(this.defaultAcc, proposalID, choices);
        // Same address vote to same proposal
        await expect(this.gov.vote(this.defaultAcc, proposalID, [1n, 3n, 4n])).to.be.revertedWith("vote already exists");
    });

    describe("checking votes for a self-voter", async function () {
        const optionsNum = 3;
        const choices = [0n, 3n, 4n];
        beforeEach("create vote", async function () {
            // Create proposal
            await createProposal(this.gov, this.verifier, NonExecutableType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), 60);
            this.proposalID = await this.gov.lastProposalID();
            // // Make new vote
            await time.increase(60);
            await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
            await this.gov.vote(this.defaultAcc, this.proposalID, choices);
        });

        it("checking voting state", async function () {
            await this.sfc.stake(this.defaultAcc, ethers.parseEther("5.0"));
            // check
            const proposalStateInfo = await this.gov.proposalState(this.proposalID);
            expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
            expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("10.0"));
            expect(proposalStateInfo.status).to.be.equal(ProposalStatus.INITIAL);
            const option0 = await this.gov.proposalOptionState(this.proposalID, 0);
            const option1 = await this.gov.proposalOptionState(this.proposalID, 1);
            const option2 = await this.gov.proposalOptionState(this.proposalID, 2);
            expect(option0.votes).to.be.equal(ethers.parseEther("10.0"));
            expect(option1.votes).to.be.equal(ethers.parseEther("10.0"));
            expect(option2.votes).to.be.equal(ethers.parseEther("10.0"));
            expect(option0.agreement).to.be.equal(ethers.parseEther("0.0"));
            expect(option1.agreement).to.be.equal(ethers.parseEther("8.0"));
            expect(option2.agreement).to.be.equal(ethers.parseEther("10.0"));
            expect(option0.agreementRatio).to.be.equal(ethers.parseEther("0.0"));
            expect(option1.agreementRatio).to.be.equal(ethers.parseEther("0.8"));
            expect(option2.agreementRatio).to.be.equal(ethers.parseEther("1.0"));
            const votingInfo = await this.gov.calculateVotingTally(this.proposalID);
            expect(votingInfo.proposalResolved).to.equal(true);
            expect(votingInfo.winnerID).to.be.equal(2n); // option with a best opinion
            expect(votingInfo.votes).to.be.equal(ethers.parseEther("10.0"));
            // clean up
            await this.gov.cancelVote(this.defaultAcc, this.proposalID);
        });

        it("cancel vote", async function () {
            await expect(this.gov.cancelVote(this.defaultAcc, this.proposalID+1n)).to.be.revertedWith("doesn't exist");
            await expect(this.gov.cancelVote(this.otherAcc, this.proposalID)).to.be.revertedWith("doesn't exist");
            await this.gov.cancelVote(this.defaultAcc, this.proposalID);
            // vote should be erased, checked by afterEach
        });

        it("recount vote", async function () {
            await this.sfc.stake(this.defaultAcc, ethers.parseEther("5.0"));
            await expect(this.gov.recountVote(this.otherAcc, this.defaultAcc, this.proposalID, {from: this.defaultAcc})).to.be.revertedWith("doesn't exist");
            await expect(this.gov.recountVote(this.defaultAcc, this.otherAcc, this.proposalID, {from: this.defaultAcc})).to.be.revertedWith("doesn't exist");
            await this.gov.recountVote(this.defaultAcc, this.defaultAcc, this.proposalID, {from: this.defaultAcc}); // anyone can send
            await expect(this.gov.recountVote(this.defaultAcc, this.defaultAcc, this.proposalID, {from: this.defaultAcc})).to.be.revertedWith("nothing changed");
            // check
            const proposalStateInfo = await this.gov.proposalState(this.proposalID);
            expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
            expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("15.0"));
            expect(proposalStateInfo.status).to.be.equal(ProposalStatus.INITIAL);
            const option0 = await this.gov.proposalOptionState(this.proposalID, 0);
            const option1 = await this.gov.proposalOptionState(this.proposalID, 1);
            const option2 = await this.gov.proposalOptionState(this.proposalID, 2);
            expect(option0.votes).to.be.equal(ethers.parseEther("15.0"));
            expect(option1.votes).to.be.equal(ethers.parseEther("15.0"));
            expect(option2.votes).to.be.equal(ethers.parseEther("15.0"));
            expect(option0.agreement).to.be.equal(ethers.parseEther("0.0"));
            expect(option1.agreement).to.be.equal(ethers.parseEther("12.0"));
            expect(option2.agreement).to.be.equal(ethers.parseEther("15.0"));
            expect(option0.agreementRatio).to.be.equal(ethers.parseEther("0.0"));
            expect(option1.agreementRatio).to.be.equal(ethers.parseEther("0.8"));
            expect(option2.agreementRatio).to.be.equal(ethers.parseEther("1.0"));
            const votingInfo = await this.gov.calculateVotingTally(this.proposalID);
            expect(votingInfo.proposalResolved).to.equal(true);
            expect(votingInfo.winnerID).to.be.equal(2n); // option with a best opinion
            expect(votingInfo.votes).to.be.equal(ethers.parseEther("15.0"));
            // clean up
            await this.gov.cancelVote(this.defaultAcc, this.proposalID);
        });

        it("cancel vote via recounting", async function () {
            this.sfc.unstake(this.defaultAcc, ethers.parseEther("10.0"));
            await this.gov.recountVote(this.defaultAcc, this.defaultAcc, this.proposalID, {from: this.defaultAcc});
            await expect(this.gov.recountVote(this.defaultAcc, this.defaultAcc, this.proposalID, {from: this.defaultAcc})).to.be.revertedWith("doesn't exist");
            // vote should be erased, checked by afterEach
        });

        it("cancel vote via recounting from VotesBookKeeper", async function () {
            this.sfc.unstake(this.defaultAcc, ethers.parseEther("10.0"));
            await this.votebook.recountVotes(this.defaultAcc, this.defaultAcc, {from: this.defaultAcc});
            expect(await this.votebook.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.empty
            await expect(this.gov.recountVote(this.defaultAcc, this.defaultAcc, this.proposalID, {from: this.defaultAcc})).to.be.revertedWith("doesn't exist");
            // vote should be erased, checked by afterEach
        });

        afterEach("checking state is empty", async function () {
            const proposalStateInfo = await this.gov.proposalState(this.proposalID);
            expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
            expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("0.0"));
            expect(proposalStateInfo.status).to.be.equal(ProposalStatus.INITIAL);
            const voteInfo = await this.gov.getVote(this.defaultAcc, this.defaultAcc, this.proposalID);
            expect(voteInfo.weight).to.be.equal(ethers.parseEther("0.0"));
            expect(voteInfo.choices.length).to.equal(0);
            const option0 = await this.gov.proposalOptionState(this.proposalID, 0);
            const option2 = await this.gov.proposalOptionState(this.proposalID, 2);
            expect(option0.votes).to.be.equal(ethers.parseEther("0.0"));
            expect(option2.votes).to.be.equal(ethers.parseEther("0.0"));
            expect(option0.agreement).to.be.equal(ethers.parseEther("0.0"));
            expect(option2.agreement).to.be.equal(ethers.parseEther("0.0"));
            expect(option0.agreementRatio).to.be.equal(ethers.parseEther("0.0"));
            expect(option2.agreementRatio).to.be.equal(ethers.parseEther("0.0"));
            const votingInfo = await this.gov.calculateVotingTally(this.proposalID);
            expect(votingInfo.proposalResolved).to.equal(false);
            expect(votingInfo.winnerID).to.be.equal(optionsNum);
            expect(votingInfo.votes).to.be.equal(ethers.parseEther("0.0"));
            await expect(this.gov.handleTasks(0, 1)).to.be.revertedWith("no tasks handled");
            await expect(this.gov.tasksCleanup(1)).to.be.revertedWith("no tasks erased");
        });
    });

    it("checking voting tally for a self-voter", async function () {
        const optionsNum = 10; // use maximum number of options to test gas usage
        const choices = [2n, 2n, 3n, 2n, 2n, 2n, 2n, 2n, 2n, 2n];
        const proposalContract = await createProposal(this.gov, this.verifier, DelegateCallType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), 60, 120);
        const proposalID = await this.gov.lastProposalID();
        // make new vote
        await time.increase(60);
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        await this.gov.vote(this.defaultAcc, proposalID, choices);

        // check proposal isn't executed
        expect(await proposalContract.executedCounter()).to.be.equal(0n);

        // check voting is ready to be finalized
        const votingInfo = await this.gov.calculateVotingTally(proposalID);
        expect(votingInfo.proposalResolved).to.equal(true);
        expect(votingInfo.winnerID).to.be.equal(2n); // option with a best opinion
        expect(votingInfo.votes).to.be.equal(ethers.parseEther("10.0"));

        // finalize voting by handling its task
        const task = await this.gov.getTask(0);
        expect(await this.gov.tasksCount()).to.be.equal(1n);
        expect(task.active).to.equal(true);
        expect(task.assignment).to.be.equal(1n);
        expect(task.proposalID).to.be.equal(proposalID);

        await expect(this.gov.handleTasks(0, 1)).to.be.revertedWith("no tasks handled");
        await time.increase(120); // wait until min voting end time
        await expect(this.gov.handleTasks(1, 1)).to.be.revertedWith("no tasks handled");
        await this.gov.handleTasks(0, 1);
        await expect(this.gov.handleTasks(0, 1)).to.be.revertedWith("no tasks handled");

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.equal(2n);
        expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("10.0"));
        expect(proposalStateInfo.status).to.be.equal(ProposalStatus.RESOLVED);

        // check proposal execution via delegatecall
        expect(await proposalContract.executedCounter()).to.be.equal(1n);
        expect(await proposalContract.executedMsgSender()).to.equal(this.defaultAcc);
        expect(await proposalContract.executedAs()).to.equal(await this.gov.getAddress());
        expect(await proposalContract.executedOption()).to.be.equal(2n);

        // try to cancel vote
        await expect(this.gov.cancelVote(this.defaultAcc, proposalID)).to.be.revertedWith("proposal isn't active");

        // try to recount vote
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("5.0"));
        await expect(this.gov.recountVote(this.defaultAcc, this.defaultAcc, proposalID, {from: this.defaultAcc})).to.be.revertedWith("proposal isn't active");

        // cleanup task
        const taskDeactivated = await this.gov.getTask(0);
        expect(await this.gov.tasksCount()).to.be.equal(1n);
        expect(taskDeactivated.active).to.equal(false);
        expect(taskDeactivated.assignment).to.be.equal(1n);
        expect(taskDeactivated.proposalID).to.be.equal(proposalID);
        await expect(this.gov.tasksCleanup(0)).to.be.revertedWith("no tasks erased");
        await this.gov.tasksCleanup(10);
        expect(await this.gov.tasksCount()).to.be.equal(0n);
    });

    it("checking proposal execution via call", async function () {
        const optionsNum = 1; // use maximum number of options to test gas usage
        const choices = [4n];
        const proposalContract = await createProposal(this.gov, this.verifier, CallType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), 0, 120);
        const proposalID = await this.gov.lastProposalID();
        // make new vote
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        await this.gov.vote(this.defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await time.increase(120); // wait until min voting end time
        await this.gov.handleTasks(0, 1);

        // check proposal execution via call
        expect(await proposalContract.executedCounter()).to.be.equal(1n);
        expect(await proposalContract.executedMsgSender()).to.equal(await this.gov.getAddress());
        expect(await proposalContract.executedAs()).to.equal(await proposalContract.getAddress());
        expect(await proposalContract.executedOption()).to.be.equal(0n);
    });

    it("checking proposal execution via delegatecall", async function () {
        const optionsNum = 1;
        const choices = [4n];
        const proposalContract = await createProposal(this.gov, this.verifier, DelegateCallType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), 0, 120);
        const proposalID = await this.gov.lastProposalID();
        // make new vote
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        await this.gov.vote(this.defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await time.increase(120); // wait until min voting end time
        await this.gov.handleTasks(0, 1);

        // check proposal execution via delegatecall
        expect(await proposalContract.executedCounter()).to.be.equal(1n);
        expect(await proposalContract.executedMsgSender()).to.equal(this.defaultAcc);
        expect(await proposalContract.executedAs()).to.equal(await this.gov.getAddress());
        expect(await proposalContract.executedOption()).to.be.equal(0n);
    });

    it("checking non-executable proposal resolving", async function () {
        const optionsNum = 2;
        const choices = [0n, 4n];
        const proposalContract = await createProposal(this.gov, this.verifier, NonExecutableType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), 0, 120);
        const proposalID = await this.gov.lastProposalID();
        // make new vote
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        await this.gov.vote(this.defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await time.increase(120); // wait until min voting end time
        await this.gov.handleTasks(0, 1);

        // check proposal execution via delegatecall
        expect(await proposalContract.executedCounter()).to.be.equal(0n);

        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.equal(1n);
        expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("10.0"));
        expect(proposalStateInfo.status).to.be.equal(ProposalStatus.RESOLVED);
    });

    it("checking proposal rejecting before max voting end is reached", async function () {
        const optionsNum = 1; // use maximum number of options to test gas usage
        const choices = [0n];
        const proposalContract = await createProposal(this.gov, this.verifier,  CallType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), 0, 120, 240);
        const proposalID = await this.gov.lastProposalID();
        // make new vote
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        await this.gov.vote(this.defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await time.increase(120); // wait until min voting end time
        await this.gov.handleTasks(0, 1);

        // check proposal is rejected
        expect(await proposalContract.executedCounter()).to.be.equal(0n);
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
        expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("10.0"));
        expect(proposalStateInfo.status).to.be.equal(ProposalStatus.FAILED);
    });

    it("checking voting tally with low turnout", async function () {
        const optionsNum = 1; // use maximum number of options to test gas usage
        const choices = [2n];
        const start = 60;
        const minEnd = 500;
        const maxEnd = 1000;
        await createProposal(this.gov, this.verifier, NonExecutableType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), start, minEnd, maxEnd);
        const proposalID = await this.gov.lastProposalID();
        // Advance time to be between min and max end
        await time.increase(start + minEnd + 10);
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        await this.gov.vote(this.defaultAcc, proposalID, choices);

        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.1")); // turnout is less than 50% now, and maxEnd has occurred
        await expect(this.gov.handleTasks(0, 1)).to.be.revertedWith("no tasks handled");
        await this.sfc.unstake(this.defaultAcc, ethers.parseEther("0.1")); // turnout is exactly 50% now
        // finalize voting by handling its task
        await this.gov.handleTasks(0, 10);

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
        expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("10.0"));
        expect(proposalStateInfo.status).to.be.equal(ProposalStatus.RESOLVED);
    });

    it("checking execution expiration", async function () {
        const optionsNum = 1; // use maximum number of options to test gas usage
        const choices = [2n];
        const start = 60;
        const minEnd = 500;
        const maxEnd = 1000;
        const proposalContract = await createProposal(this.gov, this.verifier, CallType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), start, minEnd, maxEnd);
        const proposalID = await this.gov.lastProposalID();
        const maxExecutionPeriod = await this.gov.maxExecutionPeriod();
        // Advance time to be over maxExecutionPeriod
        await time.increase(maxExecutionPeriod + BigInt(start) + BigInt(maxEnd) + 10n);
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        await this.gov.vote(this.defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await this.gov.handleTasks(0, 10);

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
        expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("10.0"));
        expect(proposalStateInfo.status).to.be.equal(ProposalStatus.EXECUTION_EXPIRED);

        // check proposal isn't executed
        expect(await proposalContract.executedCounter()).to.be.equal(0n);
    });

    it("checking proposal is rejected if low agreement after max voting end", async function () {
        const optionsNum = 1; // use maximum number of options to test gas usage
        const choices = [1n];
        const start = 60;
        const minEnd = 500;
        const maxEnd = 1000;
        const proposalContract = await createProposal(this.gov, this.verifier, CallType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), start, minEnd, maxEnd);
        const proposalID = await this.gov.lastProposalID();
        const maxExecutionPeriod = await this.gov.maxExecutionPeriod();
        // Advance time to be over maxExecutionPeriod
        await time.increase(maxExecutionPeriod + BigInt(start) + BigInt(maxEnd) + 10n);
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        await this.gov.vote(this.defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await this.gov.handleTasks(0, 10);

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
        expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("10.0"));
        expect(proposalStateInfo.status).to.be.equal(ProposalStatus.FAILED);

        // check proposal isn't executed
        expect(await proposalContract.executedCounter()).to.be.equal(0n);
    });




    it("checking execution doesn't expire earlier than needed", async function () {
        const optionsNum = 1; // use maximum number of options to test gas usage
        const choices = [2n];
        const start = 60;
        const minEnd = 500;
        const maxEnd = 1000;
        const proposalContract = await createProposal(this.gov, this.verifier, DelegateCallType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), start, minEnd, maxEnd);
        const proposalID = await this.gov.lastProposalID();
        const maxExecutionPeriod = await this.gov.maxExecutionPeriod();
        // Advance time not to exceed maxExecutionPeriod
        await time.increase(maxExecutionPeriod + BigInt(start) + BigInt(maxEnd) - 10n);
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        await this.gov.vote(this.defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await this.gov.handleTasks(0, 10);

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
        expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("10.0"));
        expect(proposalStateInfo.status).to.be.equal(ProposalStatus.RESOLVED);

        // check proposal is executed
        expect(await proposalContract.executedCounter()).to.be.equal(1n);
    });

    it("checking proposal cancellation", async function () {
        const optionsNum = 1; // use maximum number of options to test gas usage
        const choices = [2n];
        const start = 60;
        const minEnd = 500;
        const maxEnd = 1000;
        const proposalContract = await createProposal(this.gov, this.verifier, NonExecutableType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), start, minEnd, maxEnd);
        const proposalID = await this.gov.lastProposalID();
        const maxExecutionPeriod = await this.gov.maxExecutionPeriod();
        // Advance time not to exceed maxExecutionPeriod
        await time.increase(maxExecutionPeriod + BigInt(start) + BigInt(maxEnd) - 10n);
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        await this.gov.vote(this.defaultAcc, proposalID, choices);

        // try to cancel proposal
        await expect(this.gov.cancelProposal(proposalID+1n)).to.be.revertedWith("given proposalID doesn't exist");
        await expect(this.gov.cancelProposal(proposalID)).to.be.revertedWith("voting has already begun");
        await this.gov.cancelVote(this.defaultAcc, proposalID);
        await expect(this.gov.cancelProposal(proposalID)).to.be.revertedWith("sender not the proposal address");
        await proposalContract.cancel(proposalID, this.gov.getAddress());
        await expect(this.gov.cancelProposal(proposalID)).to.be.revertedWith("proposal isn't active");
        await expect(this.gov.vote(this.defaultAcc, proposalID, choices)).to.be.revertedWith("proposal isn't active");

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
        expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("0.0"));
        expect(proposalStateInfo.status).to.be.equal(ProposalStatus.CANCELED);

        // handle task
        await this.gov.handleTasks(0, 1);
        await this.gov.tasksCleanup(1);

        // check proposal status hasn't changed after the task
        const proposalStateInfoAfterTask = await this.gov.proposalState(proposalID);
        expect(proposalStateInfoAfterTask.winnerOptionID).to.be.equal(0n);
        expect(proposalStateInfoAfterTask.votes).to.be.equal(ethers.parseEther("0.0"));
        expect(proposalStateInfoAfterTask.status).to.be.equal(3n);

        // check proposal isn't executed
        expect(await proposalContract.executedCounter()).to.be.equal(0n);
    });

    it("checking handling multiple tasks", async function () {
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        const optionsNum = 1; // use maximum number of options to test gas usage
        const start = 0;
        const minEnd = 500;
        const maxEnd = 1000;
        // make 5 proposals which are ready for a finalization
        for (const i of [0, 1, 2, 3, 4]) {
            const choices = [2n];
            const proposalContract = await createProposal(this.gov, this.verifier, NonExecutableType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), start, minEnd, maxEnd);
            const proposalID = await this.gov.lastProposalID();
            // make a vote
            await this.gov.vote(this.defaultAcc, proposalID, choices);
        }
        // Advance time over earliest possible voting end
        await time.increase(minEnd + 10);

        expect(await this.gov.tasksCount()).to.be.equal(5n);
        await this.gov.handleTasks(1, 3);
        for (const i of [1, 2, 3]) {
            const proposalID = i + 1;
            // check proposal status
            const proposalStateInfo = await this.gov.proposalState(proposalID);
            expect(proposalStateInfo.status).to.be.equal(ProposalStatus.RESOLVED);
            // check task status
            const task = await this.gov.getTask(i);
            expect(task.active).to.equal(false);
        }
        for (const i of [0, 4]) {
            const proposalID = i + 1;
            // check proposal status
            const proposalStateInfo = await this.gov.proposalState(proposalID);
            expect(proposalStateInfo.status).to.be.equal(ProposalStatus.INITIAL);
            // check task status
            const task = await this.gov.getTask(i);
            expect(task.active).to.equal(true);
        }
        await expect(this.gov.tasksCleanup(1)).to.be.revertedWith("no tasks erased"); // last task is still active
        await this.gov.handleTasks(4, 1); // handle last task
        await expect(this.gov.tasksCleanup(0)).to.be.revertedWith("no tasks erased");
        await this.gov.tasksCleanup(1);
        expect(await this.gov.tasksCount()).to.be.equal(4n);
        await this.gov.tasksCleanup(4);
        expect(await this.gov.tasksCount()).to.be.equal(1n); // first task is still active
        await expect(this.gov.tasksCleanup(1)).to.be.revertedWith("no tasks erased");
        await this.gov.handleTasks(0, 1); // handle first task
        await this.gov.tasksCleanup(1);
        expect(await this.gov.tasksCount()).to.be.equal(0n);
        for (const i of [0, 1, 2, 3, 4]) {
            const proposalID = i + 1;
            // check proposal status
            const proposalStateInfo = await this.gov.proposalState(proposalID);
            expect(proposalStateInfo.status).to.be.equal(ProposalStatus.RESOLVED);
        }
    });

    it("checking proposal is rejected if low turnout after max voting end", async function () {
        const optionsNum = 1; // use maximum number of options to test gas usage
        const choices = [4n];
        const start = 60;
        const minEnd = 500;
        const maxEnd = 1000;
        const proposalContract = await createProposal(this.gov, this.verifier, CallType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), start, minEnd, maxEnd);
        const proposalID = await this.gov.lastProposalID();
        const maxExecutionPeriod = await this.gov.maxExecutionPeriod();
        // Advance time to be over maxExecutionPeriod
        await time.increase(maxExecutionPeriod + BigInt(start) + BigInt(maxEnd) + 10n);
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0")); // defaultAcc has less than 50% of weight
        await this.sfc.stake(this.firstVoterAcc, ethers.parseEther("11.0"));
        await this.gov.vote(this.defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await this.gov.handleTasks(0, 10);

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
        expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("10.0"));
        expect(proposalStateInfo.status).to.be.equal(ProposalStatus.FAILED);

        // check proposal isn't executed
        expect(await proposalContract.executedCounter()).to.be.equal(0n);
    });

    it("checking delegation vote creation", async function () {
        const optionsNum = 3;
        const choices0 = [0n, 3n, 4n];
        const choices1 = [1n, 2n, 3n];
        const start = 60;
        const minEnd = 120;
        const maxEnd = 1200;
        const proposalContract = await createProposal(this.gov, this.verifier, NonExecutableType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), start, minEnd, maxEnd);
        const proposalID = await this.gov.lastProposalID();
        // Advance time to start voting
        await time.increase(start);
        await this.sfc.connect(this.firstVoterAcc).stake(this.firstVoterAcc, ethers.parseEther("10.0"));
        await this.gov.connect(this.firstVoterAcc).vote(this.firstVoterAcc, proposalID, choices0);
        await expect(this.gov.connect(this.delegatorAcc).vote(this.firstVoterAcc, proposalID, choices1)).to.be.revertedWith("zero weight");
        await this.sfc.connect(this.delegatorAcc).stake(this.firstVoterAcc, ethers.parseEther("10.0"));
        await expect(this.gov.connect(this.delegatorAcc).vote(this.delegatorAcc, proposalID, choices1)).to.be.revertedWith("zero weight");
        await expect(this.gov.connect(this.delegatorAcc).vote(this.otherAcc, proposalID, choices1)).to.be.revertedWith("zero weight");
        await expect(this.gov.connect(this.firstVoterAcc).vote(this.delegatorAcc, proposalID, choices1)).to.be.revertedWith("zero weight");
        await expect(this.gov.vote(this.firstVoterAcc, proposalID + 1n, choices1), "given proposalID doesn't exist");
        await expect(this.gov.connect(this.delegatorAcc).vote(this.firstVoterAcc, proposalID, [3n, 4n]), "wrong number of choices");
        await expect(this.gov.connect(this.delegatorAcc).vote(this.firstVoterAcc, proposalID, [3n, 4n, 5n]), "wrong opinion ID");
        await this.gov.connect(this.delegatorAcc).vote(this.firstVoterAcc, proposalID, choices1);
        await expect(this.gov.connect(this.delegatorAcc).vote(this.firstVoterAcc, proposalID, [1n, 3n, 4n]), "vote already exists");
    });

    var votersAndDelegatorsTests = (delegatorFirst: boolean) => {
        return async function () {
            const optionsNum = 3;
            beforeEach("create vote", async function () {
                await this.sfc.addValidator(3, 0, this.secondVoterAcc)
                const start = 60;
                const minEnd = 500;
                const maxEnd = 1000;
                await createProposal(this.gov, this.verifier, CallType, optionsNum, ethers.parseEther("0.5"), ethers.parseEther("0.6"), start, minEnd, maxEnd);
                this.proposalID = await this.gov.lastProposalID();
                // make the new votes
                await time.increase(start + 10);
                if (delegatorFirst) {
                    await this.sfc.connect(this.delegatorAcc).stake(this.firstVoterAcc, ethers.parseEther("30.0"));
                    await this.gov.connect(this.delegatorAcc).vote(this.firstVoterAcc, this.proposalID, [1n, 2n, 3n]);
                }
                await this.sfc.connect(this.firstVoterAcc).stake(this.firstVoterAcc, ethers.parseEther("10.0"));
                await this.gov.connect(this.firstVoterAcc).vote(this.firstVoterAcc, this.proposalID, [3n, 2n, 0n]);
                await this.sfc.connect(this.secondVoterAcc).stake(this.secondVoterAcc, ethers.parseEther("20.0"));
                await this.gov.connect(this.secondVoterAcc).vote(this.secondVoterAcc, this.proposalID, [2n, 3n, 4n]);
                if (!delegatorFirst) {
                    await this.sfc.connect(this.delegatorAcc).stake(this.firstVoterAcc, ethers.parseEther("30.0"));
                    await this.gov.connect(this.delegatorAcc).vote(this.firstVoterAcc, this.proposalID, [1n, 2n, 3n]);
                }
            });

            it("cancel votes", async function () {
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID)).to.be.equal(ethers.parseEther("30.0"));
                const votingInfoAfter = await this.gov.calculateVotingTally(this.proposalID);
                expect(votingInfoAfter.votes).to.be.equal(ethers.parseEther("30.0"));
                expect(votingInfoAfter.proposalResolved).to.equal(true);
                expect(votingInfoAfter.winnerID).to.be.equal(2n); // option with a best opinion
                await expect(this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID+1n)).revertedWith("doesn't exist");
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID);
            });

            it("cancel votes in reversed order", async function () {
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
            });

            it("checking voting state", async function () {
                // check
                await checkFullVotes(this.firstVoterAcc, this.secondVoterAcc, this.delegatorAcc, this.proposalID, this.gov);
                // clean up
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID);
            });

            it("checking voting state after delegator re-voting", async function () {
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID, {from: this.delegatorAcc});
                await expect(this.gov.cancelVote(this.firstVoterAcc, this.proposalID)).to.be.revertedWith("doesn't exist");
                await this.gov.connect(this.delegatorAcc).vote(this.firstVoterAcc, this.proposalID, [1n, 2n, 3n]);
                // check
                await checkFullVotes(this.firstVoterAcc, this.secondVoterAcc, this.delegatorAcc, this.proposalID, this.gov);
                // clean up
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID);
            });

            it("checking voting state after first voter re-voting", async function () {
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await expect(this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID)).to.be.revertedWith("doesn't exist");
                await this.gov.connect(this.firstVoterAcc).vote(this.firstVoterAcc, this.proposalID, [3n, 2n, 0n]);
                // check
                await checkFullVotes(this.firstVoterAcc, this.secondVoterAcc, this.delegatorAcc, this.proposalID, this.gov);
                // clean up
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID);
            });

            it("checking voting state after second voter re-voting", async function () {
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
                await expect(this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID)).to.be.revertedWith("doesn't exist");
                await this.gov.connect(this.secondVoterAcc).vote(this.secondVoterAcc, this.proposalID, [2n, 3n, 4n]);
                // check
                await checkFullVotes(this.firstVoterAcc, this.secondVoterAcc, this.delegatorAcc, this.proposalID, this.gov);
                // clean up
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID);
            });

            it("checking voting state after delegator vote canceling", async function () {
                // cancel delegator vote
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID, {from: this.delegatorAcc});
                // check
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID-1n)).to.be.equal(ethers.parseEther("0.0"));
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID)).to.be.equal(ethers.parseEther("0.0"));
                const proposalStateInfo = await this.gov.proposalState(this.proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
                expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("60.0"));
                expect(proposalStateInfo.status).to.be.equal(ProposalStatus.INITIAL);
                const option0 = await this.gov.proposalOptionState(this.proposalID, 0);
                const option1 = await this.gov.proposalOptionState(this.proposalID, 1);
                const option2 = await this.gov.proposalOptionState(this.proposalID, 2);
                expect(option0.votes).to.be.equal(ethers.parseEther("60.0"));
                expect(option1.votes).to.be.equal(ethers.parseEther("60.0"));
                expect(option2.votes).to.be.equal(ethers.parseEther("60.0"));
                expect(option0.agreement).to.be.equal(ethers.parseEther("44"));
                expect(option1.agreement).to.be.equal(ethers.parseEther("40"));
                expect(option2.agreement).to.be.equal(ethers.parseEther("20"));
                expect(option0.agreementRatio).to.be.equal(ethers.parseEther("0.733333333333333333"));
                expect(option1.agreementRatio).to.be.equal(ethers.parseEther("0.666666666666666666"));
                expect(option2.agreementRatio).to.be.equal(ethers.parseEther("0.333333333333333333"));
                const votingInfo = await this.gov.calculateVotingTally(this.proposalID);
                expect(votingInfo.proposalResolved).to.equal(true);
                expect(votingInfo.winnerID).to.be.equal(0n); // option with a best opinion
                expect(votingInfo.votes).to.be.equal(ethers.parseEther("60.0"));
                // clean up
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
            });

            it("checking voting state after first staker vote canceling", async function () {
                // cancel first voter vote
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                // check
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID-1n)).to.be.equal(ethers.parseEther("0.0"));
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID)).to.be.equal(ethers.parseEther("30.0"));
                const proposalStateInfo = await this.gov.proposalState(this.proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
                expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("50.0"));
                expect(proposalStateInfo.status).to.be.equal(ProposalStatus.INITIAL);
                const option0 = await this.gov.proposalOptionState(this.proposalID, 0);
                const option1 = await this.gov.proposalOptionState(this.proposalID, 1);
                const option2 = await this.gov.proposalOptionState(this.proposalID, 2);
                expect(option0.votes).to.be.equal(ethers.parseEther("50.0"));
                expect(option1.votes).to.be.equal(ethers.parseEther("50.0"));
                expect(option2.votes).to.be.equal(ethers.parseEther("50.0"));
                expect(option0.agreement).to.be.equal(ethers.parseEther("24"));
                expect(option1.agreement).to.be.equal(ethers.parseEther("34"));
                expect(option2.agreement).to.be.equal(ethers.parseEther("44"));
                expect(option0.agreementRatio).to.be.equal(ethers.parseEther("0.48"));
                expect(option1.agreementRatio).to.be.equal(ethers.parseEther("0.68"));
                expect(option2.agreementRatio).to.be.equal(ethers.parseEther("0.88"));
                const votingInfo = await this.gov.calculateVotingTally(this.proposalID);
                expect(votingInfo.proposalResolved).to.equal(true);
                expect(votingInfo.winnerID).to.be.equal(2n); // option with a best opinion
                expect(votingInfo.votes).to.be.equal(ethers.parseEther("50.0"));
                // clean up
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
            });

            it("checking voting state after delegator recounting", async function () {
                await this.sfc.connect(this.delegatorAcc).unstake(this.firstVoterAcc, ethers.parseEther("5.0"));
                await this.gov.connect(this.otherAcc).recountVote(this.delegatorAcc, this.firstVoterAcc, this.proposalID);
                // check
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID-1n)).to.be.equal(ethers.parseEther("0.0"));
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID)).to.be.equal(ethers.parseEther("25.0"));
                const proposalStateInfo = await this.gov.proposalState(this.proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
                expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("55.0"));
                expect(proposalStateInfo.status).to.be.equal(ProposalStatus.INITIAL);
                const option0 = await this.gov.proposalOptionState(this.proposalID, 0);
                const option1 = await this.gov.proposalOptionState(this.proposalID, 1);
                const option2 = await this.gov.proposalOptionState(this.proposalID, 2);
                expect(option0.votes).to.be.equal(ethers.parseEther("55.0"));
                expect(option1.votes).to.be.equal(ethers.parseEther("55.0"));
                expect(option2.votes).to.be.equal(ethers.parseEther("55.0"));
                expect(option0.agreement).to.be.equal(ethers.parseEther("30"));
                expect(option1.agreement).to.be.equal(ethers.parseEther("37"));
                expect(option2.agreement).to.be.equal(ethers.parseEther("40"));
                expect(option0.agreementRatio).to.be.equal(ethers.parseEther("0.545454545454545454"));
                expect(option1.agreementRatio).to.be.equal(ethers.parseEther("0.672727272727272727"));
                expect(option2.agreementRatio).to.be.equal(ethers.parseEther("0.727272727272727272"));
                const votingInfo = await this.gov.calculateVotingTally(this.proposalID);
                expect(votingInfo.proposalResolved).to.equal(true);
                expect(votingInfo.winnerID).to.be.equal(2n); // option with a best opinion
                expect(votingInfo.votes).to.be.equal(ethers.parseEther("55.0"));
                // clean up
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
            });
            //
            it("checking voting state after first staker recounting", async function () {
                await this.sfc.connect(this.firstVoterAcc).stake(this.firstVoterAcc, ethers.parseEther("10.0"));
                await this.gov.connect(this.otherAcc).recountVote(this.firstVoterAcc, this.firstVoterAcc, this.proposalID);
                // check
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID-1n)).to.be.equal(ethers.parseEther("0.0"));
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID)).to.be.equal(ethers.parseEther("30.0"));
                const proposalStateInfo = await this.gov.proposalState(this.proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
                expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("70.0"));
                expect(proposalStateInfo.status).to.be.equal(ProposalStatus.INITIAL);
                const option0 = await this.gov.proposalOptionState(this.proposalID, 0);
                const option1 = await this.gov.proposalOptionState(this.proposalID, 1);
                const option2 = await this.gov.proposalOptionState(this.proposalID, 2);
                expect(option0.votes).to.be.equal(ethers.parseEther("70.0"));
                expect(option1.votes).to.be.equal(ethers.parseEther("70.0"));
                expect(option2.votes).to.be.equal(ethers.parseEther("70.0"));
                expect(option0.agreement).to.be.equal(ethers.parseEther("40"));
                expect(option1.agreement).to.be.equal(ethers.parseEther("46"));
                expect(option2.agreement).to.be.equal(ethers.parseEther("44"));
                expect(option0.agreementRatio).to.be.equal(ethers.parseEther("0.571428571428571428"));
                expect(option1.agreementRatio).to.be.equal(ethers.parseEther("0.657142857142857142"));
                expect(option2.agreementRatio).to.be.equal(ethers.parseEther("0.628571428571428571"));
                const votingInfo = await this.gov.calculateVotingTally(this.proposalID);
                expect(votingInfo.proposalResolved).to.equal(true);
                expect(votingInfo.winnerID).to.be.equal(1n); // option with a best opinion
                expect(votingInfo.votes).to.be.equal(ethers.parseEther("70.0"));
                // clean up
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
            });

            it("checking voting state after cross-delegations between voters", async function () {
                await this.sfc.connect(this.secondVoterAcc).stake(this.firstVoterAcc, ethers.parseEther("10.0"));
                await this.sfc.connect(this.firstVoterAcc).stake(this.secondVoterAcc, ethers.parseEther("5.0"));
                await this.gov.connect(this.secondVoterAcc).vote(this.firstVoterAcc, this.proposalID, [0n, 1n, 2n]);
                await expect(this.gov.connect(this.otherAcc).recountVote(this.firstVoterAcc, this.firstVoterAcc, this.proposalID)).to.be.revertedWith("nothing changed");
                await this.gov.connect(this.otherAcc).recountVote(this.secondVoterAcc, this.secondVoterAcc, this.proposalID);
                // check
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID)).to.be.equal(ethers.parseEther("40.0"));
                expect(await this.gov.overriddenWeight(this.secondVoterAcc, this.proposalID)).to.be.equal(ethers.parseEther("0.0"));
                const proposalStateInfo = await this.gov.proposalState(this.proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
                expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("75.0"));
                expect(proposalStateInfo.status).to.be.equal(ProposalStatus.INITIAL);
                const option0 = await this.gov.proposalOptionState(this.proposalID, 0);
                const option1 = await this.gov.proposalOptionState(this.proposalID, 1);
                const option2 = await this.gov.proposalOptionState(this.proposalID, 2);
                expect(option0.votes).to.be.equal(ethers.parseEther("75.0"));
                expect(option1.votes).to.be.equal(ethers.parseEther("75.0"));
                expect(option2.votes).to.be.equal(ethers.parseEther("75"));
                expect(option0.agreement).to.be.equal(ethers.parseEther("35"));
                expect(option1.agreement).to.be.equal(ethers.parseEther("48"));
                expect(option2.agreement).to.be.equal(ethers.parseEther("55"));
                expect(option0.agreementRatio).to.be.equal(ethers.parseEther("0.466666666666666666"));
                expect(option1.agreementRatio).to.be.equal(ethers.parseEther("0.64"));
                expect(option2.agreementRatio).to.be.equal(ethers.parseEther("0.733333333333333333"));
                const votingInfo = await this.gov.calculateVotingTally(this.proposalID);
                expect(votingInfo.proposalResolved).to.equal(true);
                expect(votingInfo.winnerID).to.be.equal(2n); // option with a best opinion
                expect(votingInfo.votes).to.be.equal(ethers.parseEther("75.0"));
                // clean up
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.firstVoterAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.delegatorAcc).cancelVote(this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.secondVoterAcc).cancelVote(this.secondVoterAcc, this.proposalID);
            });

            it("cancel votes via recounting", async function () {
                await this.sfc.connect(this.firstVoterAcc).unstake(this.firstVoterAcc, ethers.parseEther("10.0"));
                await this.sfc.connect(this.secondVoterAcc).unstake(this.secondVoterAcc, ethers.parseEther("20.0"));
                await this.sfc.connect(this.delegatorAcc).unstake(this.firstVoterAcc, ethers.parseEther("30.0"));
                await this.gov.connect(this.otherAcc).recountVote(this.firstVoterAcc, this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.otherAcc).recountVote(this.secondVoterAcc, this.secondVoterAcc, this.proposalID);
                await this.gov.connect(this.otherAcc).recountVote(this.delegatorAcc, this.firstVoterAcc, this.proposalID);
            });

            it("cancel votes via recounting gradually", async function () {
                await this.sfc.connect(this.firstVoterAcc).unstake(this.firstVoterAcc, ethers.parseEther("10.0"));
                await this.gov.connect(this.otherAcc).recountVote(this.firstVoterAcc, this.firstVoterAcc, this.proposalID);
                await this.sfc.connect(this.secondVoterAcc).unstake(this.secondVoterAcc, ethers.parseEther("20.0"));
                await this.gov.connect(this.otherAcc).recountVote(this.secondVoterAcc, this.secondVoterAcc, this.proposalID);
                await this.sfc.connect(this.delegatorAcc).unstake(this.firstVoterAcc, ethers.parseEther("30.0"));
                await this.gov.connect(this.otherAcc).recountVote(this.delegatorAcc, this.firstVoterAcc, this.proposalID);
            });

            it("cancel votes via recounting in reversed order", async function () {
                await this.sfc.connect(this.firstVoterAcc).unstake(this.firstVoterAcc, ethers.parseEther("10.0"));
                await this.sfc.connect(this.secondVoterAcc).unstake(this.secondVoterAcc, ethers.parseEther("20.0"));
                await this.sfc.connect(this.delegatorAcc).unstake(this.firstVoterAcc, ethers.parseEther("30.0"));
                await this.gov.connect(this.otherAcc).recountVote(this.delegatorAcc, this.firstVoterAcc, this.proposalID);
                await this.gov.connect(this.otherAcc).recountVote(this.secondVoterAcc, this.secondVoterAcc, this.proposalID);
                // firstVoterAcc"s self-vote is erased after delegator"s recounting
                await expect(this.gov.connect(this.otherAcc).recountVote(this.firstVoterAcc, this.firstVoterAcc, this.proposalID)).to.be.revertedWith("doesn't exist");
            });

            it("cancel votes via recounting gradually in reversed order", async function () {
                await this.sfc.connect(this.delegatorAcc).unstake(this.firstVoterAcc, ethers.parseEther("30.0"));
                await this.gov.connect(this.otherAcc).recountVote(this.delegatorAcc, this.firstVoterAcc, this.proposalID);
                await this.sfc.connect(this.secondVoterAcc).unstake(this.secondVoterAcc, ethers.parseEther("20.0"));
                await this.gov.connect(this.otherAcc).recountVote(this.secondVoterAcc, this.secondVoterAcc, this.proposalID);
                await this.sfc.connect(this.firstVoterAcc).unstake(this.firstVoterAcc, ethers.parseEther("10.0"));
                await this.gov.connect(this.otherAcc).recountVote(this.firstVoterAcc, this.firstVoterAcc, this.proposalID);
            });

            afterEach("checking state is empty", async function () {
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID-1n)).to.be.equal(ethers.parseEther("0.0"));
                expect(await this.gov.overriddenWeight(this.firstVoterAcc, this.proposalID)).to.be.equal(ethers.parseEther("0.0"));
                const proposalStateInfo = await this.gov.proposalState(this.proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
                expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("0.0"));
                expect(proposalStateInfo.status).to.be.equal(ProposalStatus.INITIAL);
                const voteInfo1 = await this.gov.getVote(this.firstVoterAcc, this.firstVoterAcc, this.proposalID);
                expect(voteInfo1.weight).to.be.equal(ethers.parseEther("0.0"));
                expect(voteInfo1.choices.length).to.equal(0);
                const voteInfo2 = await this.gov.getVote(this.secondVoterAcc, this.secondVoterAcc, this.proposalID);
                expect(voteInfo2.weight).to.be.equal(ethers.parseEther("0.0"));
                expect(voteInfo2.choices.length).to.equal(0);
                const voteInfo3 = await this.gov.getVote(this.delegatorAcc, this.firstVoterAcc, this.proposalID);
                expect(voteInfo3.weight).to.be.equal(ethers.parseEther("0.0"));
                expect(voteInfo3.choices.length).to.equal(0);
                const voteInfo4 = await this.gov.getVote(this.firstVoterAcc, this.delegatorAcc, this.proposalID);
                expect(voteInfo4.weight).to.be.equal(ethers.parseEther("0.0"));
                expect(voteInfo4.choices.length).to.equal(0);
                const option0 = await this.gov.proposalOptionState(this.proposalID, 0);
                const option2 = await this.gov.proposalOptionState(this.proposalID, 2);
                expect(option0.votes).to.be.equal(ethers.parseEther("0.0"));
                expect(option2.votes).to.be.equal(ethers.parseEther("0.0"));
                expect(option0.agreement).to.be.equal(ethers.parseEther("0.0"));
                expect(option2.agreement).to.be.equal(ethers.parseEther("0.0"));
                expect(option0.agreementRatio).to.be.equal(ethers.parseEther("0.0"));
                expect(option2.agreementRatio).to.be.equal(ethers.parseEther("0.0"));
                const votingInfo = await this.gov.calculateVotingTally(this.proposalID);
                expect(votingInfo.proposalResolved).to.equal(false);
                expect(votingInfo.winnerID).to.be.equal(optionsNum);
                expect(votingInfo.votes).to.be.equal(ethers.parseEther("0.0"));
                await expect(this.gov.handleTasks(0, 1)).to.be.revertedWith("no tasks handled");
                await expect(this.gov.tasksCleanup(1)).to.be.revertedWith("no tasks erased");
                await expect(this.gov.connect(this.otherAcc).recountVote(this.firstVoterAcc, this.firstVoterAcc, this.proposalID)).to.be.revertedWith("doesn't exist");
                await expect(this.gov.connect(this.otherAcc).recountVote(this.delegatorAcc, this.firstVoterAcc, this.proposalID)).to.be.revertedWith("doesn't exist");
                await expect(this.gov.connect(this.otherAcc).recountVote(this.secondVoterAcc, this.secondVoterAcc, this.proposalID)).to.be.revertedWith("doesn't exist");
            });
        }
    }
    describe("checking votes for 1 delegation and 2 self-voters", votersAndDelegatorsTests(true));
    describe("checking votes for 2 self-voters and 1 delegation", votersAndDelegatorsTests(false));

    it("checking voting with custom parameters", async function () {
        await expect(this.verifier.addTemplate(99, "custom", ethers.ZeroAddress, NonExecutableType, ethers.parseEther("1.1"), ethers.parseEther("0.6"), scales, 120, 1200, 0, 60))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinVotesOverflow"
            )
        await expect(this.verifier.addTemplate(99, "custom", ethers.ZeroAddress, NonExecutableType, ethers.parseEther("0.4"), ethers.parseEther("1.1"), scales, 120, 1200, 0, 60))
            .to.be.revertedWithCustomError(
                this.verifier,
                "MinAgreementOverflow"
            )
        await expect(this.verifier.addTemplate(99, "custom", ethers.ZeroAddress, NonExecutableType, ethers.parseEther("0.4"), ethers.parseEther("0.6"), [], 120, 1200, 0, 60))
            .to.be.revertedWithCustomError(
                this.verifier,
                "EmptyOpinions"
            )
        await expect(this.verifier.addTemplate(99, "custom", ethers.ZeroAddress, NonExecutableType, ethers.parseEther("0.4"), ethers.parseEther("0.6"), [1, 2, 3, 0], 120, 1200, 0, 60))
            .to.be.revertedWithCustomError(
                this.verifier,
                "OpinionsNotSorted"
            )
        await expect(this.verifier.addTemplate(99, "custom", ethers.ZeroAddress, NonExecutableType, ethers.parseEther("0.4"), ethers.parseEther("0.6"), [0, 0, 0, 0], 120, 1200, 0, 60))
            .to.be.revertedWithCustomError(
                this.verifier,
                "AllOpinionsZero"
            )
        await expect(this.verifier.addTemplate(99, "custom", ethers.ZeroAddress, NonExecutableType, ethers.parseEther("0.4"), ethers.parseEther("0.6"), [0], 120, 1200, 0, 60))
            .to.be.revertedWithCustomError(
                this.verifier,
                "AllOpinionsZero"
            )
        const optionsNum = 1; // use maximum number of options to test gas usage
        const start = 10000;
        const minEnd = 100000;
        const maxEnd = 1000000;
        await createProposal(
            this.gov,
            this.verifier,
            NonExecutableType,
            optionsNum,
            ethers.parseEther("0.01"),
            ethers.parseEther("1.0"),
            start,
            minEnd,
            maxEnd,
            [1000000000000]
        );
        const proposalID = await this.gov.lastProposalID();
        // Advance time not to over mininal end time
        await time.increase(minEnd + 10);
        await this.sfc.stake(this.defaultAcc, ethers.parseEther("10.0"));
        // only 1 opinion is defined
        await expect(this.gov.vote(this.defaultAcc, proposalID, [1n])).to.be.revertedWith("wrong opinion ID");
        await this.gov.vote(this.defaultAcc, proposalID, [0n]);

        // check voting
        const votingInfo = await this.gov.calculateVotingTally(proposalID);
        expect(votingInfo.proposalResolved).to.equal(true);
        expect(votingInfo.winnerID).to.be.equal(0n); // option with a best opinion
        expect(votingInfo.votes).to.be.equal(ethers.parseEther("10.0"));
        const option0 = await this.gov.proposalOptionState(proposalID, 0);
        expect(option0.votes).to.be.equal(ethers.parseEther("10.0"));
        expect(option0.agreement).to.be.equal(ethers.parseEther("10"));
        expect(option0.agreementRatio).to.be.equal(ethers.parseEther("1.0"));
    });

    it("checking OwnableVerifier", async function () {
        const ownableVerifier = await ethers.deployContract("OwnableVerifier", [await this.gov.getAddress()], {from: this.defaultAcc})
        await this.verifier.addTemplate(1, "plaintext", await ownableVerifier.getAddress(), NonExecutableType, ethers.parseEther("0.4"), ethers.parseEther("0.6"), [0, 1, 2, 3, 4], 120, 1200, 0, 60);
        const option = ethers.encodeBytes32String("opt");
        const proposal = await ethers.deployContract("PlainTextProposal", ["paintext", "plaintext-descr", [option], ethers.parseEther("0.5"), ethers.parseEther("0.8"), 30, 121, 1199, this.verifierAddress]);

        await expect(this.gov.connect(this.otherAcc).createProposal(proposal.getAddress(), {value: this.proposalFee}))
            .to.be.revertedWithCustomError(
                ownableVerifier,
                "AppropriateFactoryNotUsed"
            )
        await expect(this.gov.connect(this.defaultAcc).createProposal(proposal.getAddress(), {value: this.proposalFee}))
            .to.be.revertedWithCustomError(
                ownableVerifier,
                "AppropriateFactoryNotUsed"
            )
        await expect(ownableVerifier.connect(this.otherAcc).createProposal(proposal.getAddress(), {value: this.proposalFee})).to.be.revertedWithCustomError(
            ownableVerifier,
            'OwnableUnauthorizedAccount',
        );
        await ownableVerifier.connect(this.defaultAcc).createProposal(proposal.getAddress(), {value: this.proposalFee});
        await expect(this.gov.connect(this.otherAcc).createProposal(proposal.getAddress(), {value: this.proposalFee}))
            .to.be.revertedWithCustomError(
                ownableVerifier,
                "AppropriateFactoryNotUsed"
            )
        await expect(this.gov.connect(this.defaultAcc).createProposal(proposal.getAddress(), {value: this.proposalFee}))
            .to.be.revertedWithCustomError(
                ownableVerifier,
                "AppropriateFactoryNotUsed"
            )
        await expect(ownableVerifier.connect(this.otherAcc).createProposal(proposal.getAddress(), {value: this.proposalFee})).to.be.revertedWithCustomError(
            ownableVerifier,
            'OwnableUnauthorizedAccount',
        );

        // Transfer ownership to otherAcc
        await ownableVerifier.connect(this.defaultAcc).transferOwnership(this.otherAcc);

        await expect(this.gov.connect(this.defaultAcc).createProposal(proposal.getAddress(), {value: this.proposalFee}))
            .to.be.revertedWithCustomError(
                ownableVerifier,
                "AppropriateFactoryNotUsed"
            )
        await expect(this.gov.connect(this.otherAcc).createProposal(proposal.getAddress(), {value: this.proposalFee}))
            .to.be.revertedWithCustomError(
                ownableVerifier,
                "AppropriateFactoryNotUsed"
            )
        await expect(ownableVerifier.connect(this.defaultAcc).createProposal(proposal.getAddress(), {value: this.proposalFee})).to.be.revertedWithCustomError(
            ownableVerifier,
            'OwnableUnauthorizedAccount',
        );
        await ownableVerifier.connect(this.otherAcc).createProposal(proposal.getAddress(), {value: this.proposalFee});
    });

    it("checking SlashingRefundProposal naming scheme", async function () {
        await this.verifier.addTemplate(5003, "SlashingRefundProposals", ethers.ZeroAddress, DelegateCallType, ethers.parseEther("0.5"), ethers.parseEther("0.8"), [0, 1, 2, 3, 4], 121, 1199, 30, 30);

        const proposal0 = await ethers.deployContract("SlashingRefundProposal", [0, "description", ethers.parseEther("0.5"), ethers.parseEther("0.8"), 30, 121, 1199, ethers.ZeroAddress, this.verifierAddress]);
        const proposal1 = await ethers.deployContract("SlashingRefundProposal", [1, "description", ethers.parseEther("0.5"), ethers.parseEther("0.8"), 30, 121, 1199, ethers.ZeroAddress, this.verifierAddress]);
        const proposal5 = await ethers.deployContract("SlashingRefundProposal", [5, "description", ethers.parseEther("0.5"), ethers.parseEther("0.8"), 30, 121, 1199, ethers.ZeroAddress, this.verifierAddress]);
        const proposal9 = await ethers.deployContract("SlashingRefundProposal", [9, "description", ethers.parseEther("0.5"), ethers.parseEther("0.8"), 30, 121, 1199, ethers.ZeroAddress, this.verifierAddress]);
        const proposal10 = await ethers.deployContract("SlashingRefundProposal", [10, "description", ethers.parseEther("0.5"), ethers.parseEther("0.8"), 30, 121, 1199, ethers.ZeroAddress, this.verifierAddress]);
        const proposal21 = await ethers.deployContract("SlashingRefundProposal", [21, "description", ethers.parseEther("0.5"), ethers.parseEther("0.8"), 30, 121, 1199, ethers.ZeroAddress, this.verifierAddress]);
        const proposal99 = await ethers.deployContract("SlashingRefundProposal", [99, "description", ethers.parseEther("0.5"), ethers.parseEther("0.8"), 30, 121, 1199, ethers.ZeroAddress, this.verifierAddress]);
        const proposal100 = await ethers.deployContract("SlashingRefundProposal", [100, "description", ethers.parseEther("0.5"), ethers.parseEther("0.8"), 30, 121, 1199, ethers.ZeroAddress, this.verifierAddress]);
        const proposal999 = await ethers.deployContract("SlashingRefundProposal", [999, "description", ethers.parseEther("0.5"), ethers.parseEther("0.8"), 30, 121, 1199, ethers.ZeroAddress, this.verifierAddress]);

        expect(await proposal0.description()).to.equal("description");

        expect(await proposal0.name()).to.equal("Refund for Slashed Validator #0");
        expect(await proposal1.name()).to.equal("Refund for Slashed Validator #1");
        expect(await proposal5.name()).to.equal("Refund for Slashed Validator #5");
        expect(await proposal9.name()).to.equal("Refund for Slashed Validator #9");
        expect(await proposal10.name()).to.equal("Refund for Slashed Validator #10");
        expect(await proposal21.name()).to.equal("Refund for Slashed Validator #21");
        expect(await proposal99.name()).to.equal("Refund for Slashed Validator #99");
        expect(await proposal100.name()).to.equal("Refund for Slashed Validator #100");
        expect(await proposal999.name()).to.equal("Refund for Slashed Validator #999");
    });
});

// createProposal deploys and proposes an 'ExecLoggingProposal' proposal with the given parameters,
// it excludes the verification by passing zero address as the verifier address param.
// If not already deployed, it also deploys a very benevolent verifier.
const createProposal = async (
    gov: Governance,
    verifier: ProposalTemplates,
    execType: bigint,
    optionsNum: number,
    minVotes: any,
    minAgreement: any,
    startDelay = 0,
    minEnd = 120,
    maxEnd = 1200,
    opinionScales = [0, 2, 3, 4, 5],
): Promise<ExecLoggingProposal> => {
    if (await verifier.exists(15) === false) {
        const proposalType = 15;
        const name = "ExecLoggingProposal";
        const verifierAddr = ethers.ZeroAddress; // Skip verification
        const templMinVotes = ethers.parseEther("0.0"); // no need to limit in test
        const templMinAgreement = ethers.parseEther("0.0"); // no need to limit in test
        const minVotingDuration = 0; // no need to limit in test
        const maxVotingDuration = 100000000; // no need to limit in test
        const minStartDelay = 0; // no need to limit in test
        const maxStartDelay = 100000000; // no need to limit in test
        await verifier.addTemplate(
            proposalType,
            name,
            verifierAddr,
            execType,
            templMinVotes,
            templMinAgreement,
            opinionScales,
            minVotingDuration,
            maxVotingDuration,
            minStartDelay,
            maxStartDelay
        );
    }
    const option = ethers.encodeBytes32String("opt");
    const options = [];
    for (let i = 0; i < optionsNum; i++) {
        options.push(option);
    }
    const contract = await ethers.deployContract(
        "ExecLoggingProposal",
        ["logger", "logger-descr", options, minVotes, minAgreement, startDelay, minEnd, maxEnd, ethers.ZeroAddress]
    );
    await contract.setOpinionScales(opinionScales);
    await contract.setExecutable(execType);
    await gov.createProposal(contract.getAddress(), {value: await gov.proposalFee()});

    return contract
};

// checkFullVotes checks the voting state after 3 votes are casted: 10, 20, 30 tokens.
// The first voter votes for the first option, the second voter votes for the second option,
//
const checkFullVotes = async function (
    firstVoterAcc: HardhatEthersSigner,
    secondVoterAcc: HardhatEthersSigner,
    delegatorAcc: HardhatEthersSigner,
    proposalID: bigint,
    gov: Governance,
) {
    // firstVotedAcc has delegated 10 eth to himself and voted with all of it
    const voteInfo1 = await gov.getVote(firstVoterAcc, firstVoterAcc, proposalID);
    expect(voteInfo1.weight).to.be.equal(ethers.parseEther("10.0"));
    expect(voteInfo1.choices.length).to.equal(3);
    // secondVotedAcc has delegated 20 eth to himself and voted with all of it
    const voteInfo2 = await gov.getVote(secondVoterAcc, secondVoterAcc, proposalID);
    expect(voteInfo2.weight).to.be.equal(ethers.parseEther("20.0"));
    expect(voteInfo2.choices.length).to.equal(3);
    // delegatorAcc has delegated 30 eth to firstVoterAcc and voted with all of it
    const voteInfo3 = await gov.getVote(delegatorAcc, firstVoterAcc, proposalID);
    expect(voteInfo3.weight).to.be.equal(ethers.parseEther("30.0"));
    expect(voteInfo3.choices.length).to.equal(3);
    // no vote with this specification exists
    const voteInfo4 = await gov.getVote(firstVoterAcc, delegatorAcc, proposalID);
    expect(voteInfo4.weight).to.be.equal(ethers.parseEther("0.0"));
    expect(voteInfo4.choices.length).to.equal(0);
    expect(await gov.overriddenWeight(firstVoterAcc, proposalID-1n)).to.be.equal(ethers.parseEther("0.0"));
    expect(await gov.overriddenWeight(firstVoterAcc, proposalID)).to.be.equal(ethers.parseEther("30.0"));

    const proposalStateInfo = await gov.proposalState(proposalID);
    // winner should be first option
    expect(proposalStateInfo.winnerOptionID).to.be.equal(0n);
    // total of 60 eth voted
    expect(proposalStateInfo.votes).to.be.equal(ethers.parseEther("60.0"));
    expect(proposalStateInfo.status).to.be.equal(ProposalStatus.INITIAL);
    const option0 = await gov.proposalOptionState(proposalID, 0);
    const option1 = await gov.proposalOptionState(proposalID, 1);
    const option2 = await gov.proposalOptionState(proposalID, 2);
    expect(option0.votes).to.be.equal(ethers.parseEther("60.0"));
    expect(option1.votes).to.be.equal(ethers.parseEther("60.0"));
    expect(option2.votes).to.be.equal(ethers.parseEther("60.0"));
    // check voting calculation correctness
    expect(option0.agreement).to.be.equal(ethers.parseEther("32"));
    expect(option1.agreement).to.be.equal(ethers.parseEther("40"));
    expect(option2.agreement).to.be.equal(ethers.parseEther("44"));
    expect(option0.agreementRatio).to.be.equal(ethers.parseEther("0.533333333333333333"));
    expect(option1.agreementRatio).to.be.equal(ethers.parseEther("0.666666666666666666"));
    expect(option2.agreementRatio).to.be.equal(ethers.parseEther("0.733333333333333333"));
    const votingInfo = await gov.calculateVotingTally(proposalID);
    expect(votingInfo.proposalResolved).to.equal(true);
    // option2 has won
    expect(votingInfo.winnerID).to.be.equal(2n);
    expect(votingInfo.votes).to.be.equal(ethers.parseEther("60.0"));
};