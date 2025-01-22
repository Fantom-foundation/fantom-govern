import { expect } from "chai";
import {ethers} from "hardhat";
import {randomAddressString} from "hardhat/internal/hardhat-network/provider/utils/random";

describe("VotesBook", function () {
    beforeEach("Deploy VotesBook", async function (){
        // Init used accounts
        [this.defaultAcc, this.otherAcc] = await ethers.getSigners();
        this.votesBookKeeper = await ethers.deployContract("VotesBookKeeper");
        // Only one vote per address is allowed
        this.fakeGov = await ethers.deployContract("FakeVoteRecounter");
    })
    it("onVoted() should record two votes from one voter to two different proposals", async function () {
        this.votesBookKeeper.initialize(this.defaultAcc, randomAddressString(), 2);
        const delegatedTo = randomAddressString();
        const proposalID1 = 1n;
        const proposalID2 = 2n;
        // First vote
        await this.votesBookKeeper.onVoted(this.otherAcc, delegatedTo, proposalID1);
        // Second vote
        await this.votesBookKeeper.onVoted(this.otherAcc, delegatedTo, proposalID2);
        expect(await this.votesBookKeeper.getProposalIDs(this.otherAcc, delegatedTo)).to.deep.equal([proposalID1, proposalID2]);
    });
    it("onVoted() should revert when received too many votes from one voter", async function () {
        this.votesBookKeeper.initialize(this.defaultAcc, randomAddressString(), 2);
        const delegatedTo = randomAddressString();
        const proposalID1 = 1n;
        const proposalID2 = 2n;
        const proposalID3 = 3n;
        // Two votes will pass
        await this.votesBookKeeper.onVoted(this.otherAcc, delegatedTo, proposalID1);
        await this.votesBookKeeper.onVoted(this.otherAcc, delegatedTo, proposalID2);
        // Third will revert
        await expect(this.votesBookKeeper.onVoted(this.otherAcc, delegatedTo, proposalID3)).to.revertedWith("too many votes")
    });
    it("onVoteCanceled() removes vote", async function () {
        this.votesBookKeeper.initialize(this.defaultAcc, randomAddressString(), 2);
        const delegatedTo = randomAddressString();
        const proposalID = 1n;
        await this.votesBookKeeper.onVoted(this.otherAcc, delegatedTo, proposalID);
        await this.votesBookKeeper.onVoteCanceled(this.otherAcc, delegatedTo, proposalID);
        expect(await this.votesBookKeeper.getProposalIDs(this.otherAcc, delegatedTo)).to.deep.equal([]);
        // 0n means there is no vote index
        expect(await this.votesBookKeeper.getVoteIndex(this.otherAcc, delegatedTo, proposalID)).to.equal(0n);
    });

    it("checking VotesBookKeeper proposals cap", async function () {
        await this.votesBookKeeper.initialize(this.defaultAcc.getAddress(), this.fakeGov.getAddress(), 1);
        expect(await this.votesBookKeeper.owner()).to.equal(this.defaultAcc);
        await this.fakeGov.reset(this.defaultAcc, this.defaultAcc);
        await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 1);
        await expect(this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 2)).to.be.revertedWith("too many votes");
        await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 1);
        await this.votesBookKeeper.setMaxProposalsPerVoter(2);
        await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 2);
        await expect(this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 3)).to.be.revertedWith("too many votes");

        await this.fakeGov.reset(this.defaultAcc, this.defaultAcc);
        await this.fakeGov.setOutdatedProposals([2]);
        await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 3);

        expect(await this.fakeGov.failed()).to.equal(false);
        expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.deep.equal([1n, 3n]);
        expect(await this.fakeGov.getRecounted()).to.be.deep.equal([1n]);
        expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(1n);
        expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 2)).to.be.equal(0n);
        expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 3)).to.be.equal(2n);

        await this.fakeGov.reset(this.defaultAcc, this.defaultAcc);
        await this.fakeGov.setOutdatedProposals([1]);
        await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 2);

        expect(await this.fakeGov.failed()).to.equal(false);
        expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.deep.equal([3n, 2n]);
        expect(await this.fakeGov.getRecounted()).to.be.deep.equal([3n]);
        expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(0n);
        expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 2)).to.be.equal(2n);
        expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 3)).to.be.equal(1n);
    });

    it("checking VotesBookKeeper pruning outdated votes", async function () {
        await this.votesBookKeeper.initialize(this.defaultAcc.getAddress(), this.fakeGov.getAddress(), 1000);
        expect(await this.votesBookKeeper.owner()).to.equal(this.defaultAcc);
        {
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 1);
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 2);
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 3);

            await this.fakeGov.reset(this.defaultAcc, this.defaultAcc);
            await this.votesBookKeeper.recountVotes(this.defaultAcc, this.defaultAcc);
            expect(await this.fakeGov.failed()).to.equal(false);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.deep.equal([1n, 2n, 3n]);
            expect(await this.fakeGov.getRecounted()).to.be.deep.equal([1n, 2n, 3n]);

            await this.fakeGov.reset(this.defaultAcc, this.defaultAcc);
            await this.fakeGov.setOutdatedProposals([2]);
            await this.votesBookKeeper.recountVotes(this.defaultAcc, this.defaultAcc);
            expect(await this.fakeGov.failed()).to.equal(false);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.deep.equal([1n, 3n]);
            expect(await this.fakeGov.getRecounted()).to.be.deep.equal([1n, 3n]);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(1n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 2)).to.be.equal(0n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 3)).to.be.equal(2n);

            await this.fakeGov.reset(this.defaultAcc, this.defaultAcc);
            await this.fakeGov.setOutdatedProposals([1, 3]);
            await this.votesBookKeeper.recountVotes(this.defaultAcc, this.defaultAcc);
            expect(await this.fakeGov.failed()).to.equal(false);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.empty
            expect(await this.fakeGov.getRecounted()).to.be.empty;
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(0n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 2)).to.be.equal(0n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 3)).to.be.equal(0n);
        }
    });

    it("checking VotesBookKeeper indexes", async function () {
        await this.votesBookKeeper.initialize(this.defaultAcc.getAddress(), this.fakeGov.getAddress(), 1000);
        expect(await this.votesBookKeeper.owner()).to.equal(this.defaultAcc);
        {
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 1);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.deep.equal([ 1n ]);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(1n);
            // duplicate vote
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 1);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.deep.equal([ 1n ]);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(1n);

            await this.votesBookKeeper.onVoteCanceled(this.defaultAcc, this.defaultAcc, 1);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.empty;
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(0n);
            // duplicate cancelling
            await this.votesBookKeeper.onVoteCanceled(this.defaultAcc, this.defaultAcc, 1);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.empty;
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(0n);
        }

        {
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 1);
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 2);
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 3);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.deep.equal([1n, 2n, 3n]);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(1n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 2)).to.be.equal(2n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 3)).to.be.equal(3n);

            // in straight order
            await this.votesBookKeeper.onVoteCanceled(this.defaultAcc, this.defaultAcc, 1);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.deep.equal([3n, 2n]);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(0n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 2)).to.be.equal(2n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 3)).to.be.equal(1n);
            await this.votesBookKeeper.onVoteCanceled(this.defaultAcc, this.defaultAcc, 2);
            await this.votesBookKeeper.onVoteCanceled(this.defaultAcc, this.defaultAcc, 3);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.empty;
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(0n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 2)).to.be.equal(0n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 3)).to.be.equal(0n);
        }
        {
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 1);
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 2);
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 3);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.deep.equal([1n, 2n, 3n]);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(1n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 2)).to.be.equal(2n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 3)).to.be.equal(3n);

            // in reverse order
            await this.votesBookKeeper.onVoteCanceled(this.defaultAcc, this.defaultAcc, 3);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.deep.equal([1n, 2n]);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(1n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 2)).to.be.equal(2n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 3)).to.be.equal(0n);
            await this.votesBookKeeper.onVoteCanceled(this.defaultAcc, this.defaultAcc, 2);
            await this.votesBookKeeper.onVoteCanceled(this.defaultAcc, this.defaultAcc, 1);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.empty;
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(0n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 2)).to.be.equal(0n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 3)).to.be.equal(0n);
        }
        {
            // different accounts
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.defaultAcc, 1);
            await this.votesBookKeeper.onVoted(this.defaultAcc, this.otherAcc, 2);
            await this.votesBookKeeper.onVoted(this.otherAcc, this.defaultAcc, 3);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.deep.equal([ 1n ]);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(1n);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.otherAcc)).to.be.deep.equal([ 2n ]);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.otherAcc, 1)).to.be.equal(0n);
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.otherAcc, 2)).to.be.equal(1n);
            expect(await this.votesBookKeeper.getProposalIDs(this.otherAcc, this.defaultAcc)).to.be.deep.equal([ 3n ]);
            expect(await this.votesBookKeeper.getVoteIndex(this.otherAcc, this.defaultAcc, 3)).to.be.equal(1n);

            await this.votesBookKeeper.onVoteCanceled(this.defaultAcc, this.defaultAcc, 1);
            await this.votesBookKeeper.onVoteCanceled(this.defaultAcc, this.otherAcc, 2);
            await this.votesBookKeeper.onVoteCanceled(this.otherAcc, this.defaultAcc, 3);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.defaultAcc)).to.be.empty;
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.defaultAcc, 1)).to.be.equal(0n);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.otherAcc)).to.be.empty;
            expect(await this.votesBookKeeper.getVoteIndex(this.defaultAcc, this.otherAcc, 1)).to.be.equal(0n);
            expect(await this.votesBookKeeper.getProposalIDs(this.defaultAcc, this.otherAcc)).to.be.empty;
            expect(await this.votesBookKeeper.getVoteIndex(this.otherAcc, this.defaultAcc, 1)).to.be.equal(0n);
        }
    });
})
