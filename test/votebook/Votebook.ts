import { expect } from "chai";
import {ethers} from "hardhat";
import {randomAddressString} from "hardhat/internal/hardhat-network/provider/utils/random";

describe("VotesBook", function () {
    beforeEach("Deploy VotesBook", async function (){
        this.votesBook = await ethers.deployContract("VotesBookKeeper");
        this.owner = randomAddressString();
        // Only one vote per address is allowed
        this.votesBook.initialize(this.owner, randomAddressString(), 2);
    })
    it("onVoted() should record two votes from one voter to two different proposals", async function () {
        const voter = randomAddressString();
        const delegatedTo = randomAddressString();
        const proposalID1 = 1n;
        const proposalID2 = 2n;
        // First vote
        await this.votesBook.onVoted(voter, delegatedTo, proposalID1);
        // Second vote
        await this.votesBook.onVoted(voter, delegatedTo, proposalID2);
        expect(await this.votesBook.getProposalIDs(voter, delegatedTo)).to.deep.equal([proposalID1, proposalID2]);
    });
    it("onVoted() should revert when received too many votes from one voter", async function () {
        const voter = randomAddressString();
        const delegatedTo = randomAddressString();
        const proposalID1 = 1n;
        const proposalID2 = 2n;
        const proposalID3 = 3n;
        // Two votes will pass
        await this.votesBook.onVoted(voter, delegatedTo, proposalID1);
        await this.votesBook.onVoted(voter, delegatedTo, proposalID2);
        // Third will revert
        await expect(this.votesBook.onVoted(voter, delegatedTo, proposalID3)).to.revertedWith("too many votes")
    });
    it("onVoteCanceled() removes vote", async function () {
        const voter = randomAddressString();
        const delegatedTo = randomAddressString();
        const proposalID = 1n;
        await this.votesBook.onVoted(voter, delegatedTo, proposalID);
        await this.votesBook.onVoteCanceled(voter, delegatedTo, proposalID);
        expect(await this.votesBook.getProposalIDs(voter, delegatedTo)).to.deep.equal([]);
        // 0n means there is no vote index
        expect(await this.votesBook.getVoteIndex(voter, delegatedTo, proposalID)).to.equal(0n);
    });

});

