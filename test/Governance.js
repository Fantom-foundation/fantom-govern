const { time } = require('openzeppelin-test-helpers');
const {
    BN,
    ether,
    expectRevert,
    balance,
} = require('@openzeppelin/test-helpers');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const { expect } = require('chai');
const { evm } = require('./test-utils');
chai.use(chaiAsPromised);

const Governance = artifacts.require('UnitTestGovernance');
const ProposalTemplates = artifacts.require('ProposalTemplates');
const UnitTestGovernable = artifacts.require('UnitTestGovernable');
const PlainTextProposal = artifacts.require('PlainTextProposal');
const ExplicitProposal = artifacts.require('ExplicitProposal');
const ExecLoggingProposal = artifacts.require('ExecLoggingProposal');
const PlainTextProposalFactory = artifacts.require('PlainTextProposalFactory');
const OwnableVerifier = artifacts.require('OwnableVerifier');
const SlashingRefundProposal = artifacts.require('SlashingRefundProposal');
const NetworkParameterProposalFactory = artifacts.require('NetworkParameterProposalFactory');
const UnitTestMockSFC = artifacts.require('UnitTestMockSFC');
const VotesBookKeeper = artifacts.require('VotesBookKeeper');
const FakeVoteRecounter = artifacts.require('FakeVoteRecounter');

const NonExecutableType = new BN('0');
const CallType = new BN('1');
const DelegatecallType = new BN('2');

const MAX_DELEGATION = 1;
const VALIDATOR_COMMISSION_FEE = 2;
const CONTRACT_COMMISSION_FEE = 3;
const UNLOCKED_REWARD = 4;
const MIN_LOCKUP = 5;
const MAX_LOCKUP = 6;
const WITHDRAWAL_PERIOD_EPOCH_VALUE = 7;
const WITHDRAWAL_PERIOD_TIME_VALUE = 8;
const MIN_SELF_STAKE = 9;

function ratio(n) {
    return ether(n);
}

const emptyAddr = '0x0000000000000000000000000000000000000000';

function arrayBNEqual(a, b) {
    expect(a.length).to.equal(b.length);
    for (let i = 0; i < a.length; i++) {
        expect(a[i]).to.be.bignumber.equal(b[i]);
    }
}

contract('VoteBookKeeper test', async ([defaultAcc, otherAcc]) => {

    it('checking votes bookkeeper indexes', async () => {
        const votebook = await VotesBookKeeper.new();
        const fakeGov = await FakeVoteRecounter.new();
        await votebook.initialize(defaultAcc, fakeGov.address, 1000);
        expect(await votebook.owner()).to.equal(defaultAcc);

        {
            await votebook.onVoted(defaultAcc, defaultAcc, 1);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), [ new BN(1) ]);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(1));
            // duplicate vote
            await votebook.onVoted(defaultAcc, defaultAcc, 1);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), [ new BN(1) ]);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(1));

            await votebook.onVoteCanceled(defaultAcc, defaultAcc, 1);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), []);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(0));
            // duplicate cancelling
            await votebook.onVoteCanceled(defaultAcc, defaultAcc, 1);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), []);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(0));
        }

        {
            await votebook.onVoted(defaultAcc, defaultAcc, 1);
            await votebook.onVoted(defaultAcc, defaultAcc, 2);
            await votebook.onVoted(defaultAcc, defaultAcc, 3);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), [new BN(1), new BN(2), new BN(3)]);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(1));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 2)).to.be.bignumber.equal(new BN(2));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 3)).to.be.bignumber.equal(new BN(3));

            // in straight order
            await votebook.onVoteCanceled(defaultAcc, defaultAcc, 1);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), [new BN(3), new BN(2)]);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(0));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 2)).to.be.bignumber.equal(new BN(2));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 3)).to.be.bignumber.equal(new BN(1));
            await votebook.onVoteCanceled(defaultAcc, defaultAcc, 2);
            await votebook.onVoteCanceled(defaultAcc, defaultAcc, 3);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), []);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(0));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 2)).to.be.bignumber.equal(new BN(0));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 3)).to.be.bignumber.equal(new BN(0));
        }

        {
            await votebook.onVoted(defaultAcc, defaultAcc, 1);
            await votebook.onVoted(defaultAcc, defaultAcc, 2);
            await votebook.onVoted(defaultAcc, defaultAcc, 3);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), [new BN(1), new BN(2), new BN(3)]);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(1));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 2)).to.be.bignumber.equal(new BN(2));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 3)).to.be.bignumber.equal(new BN(3));

            // in reverse order
            await votebook.onVoteCanceled(defaultAcc, defaultAcc, 3);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), [new BN(1), new BN(2)]);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(1));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 2)).to.be.bignumber.equal(new BN(2));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 3)).to.be.bignumber.equal(new BN(0));
            await votebook.onVoteCanceled(defaultAcc, defaultAcc, 2);
            await votebook.onVoteCanceled(defaultAcc, defaultAcc, 1);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), []);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(0));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 2)).to.be.bignumber.equal(new BN(0));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 3)).to.be.bignumber.equal(new BN(0));
        }

        {
            // different accounts
            await votebook.onVoted(defaultAcc, defaultAcc, 1);
            await votebook.onVoted(defaultAcc, otherAcc, 2);
            await votebook.onVoted(otherAcc, defaultAcc, 3);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), [ new BN(1) ]);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(1));
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, otherAcc), [ new BN(2) ]);
            expect(await votebook.getVoteIndex.call(defaultAcc, otherAcc, 1)).to.be.bignumber.equal(new BN(0));
            expect(await votebook.getVoteIndex.call(defaultAcc, otherAcc, 2)).to.be.bignumber.equal(new BN(1));
            arrayBNEqual(await votebook.getProposalIDs.call(otherAcc, defaultAcc), [ new BN(3) ]);
            expect(await votebook.getVoteIndex.call(otherAcc, defaultAcc, 3)).to.be.bignumber.equal(new BN(1));

            await votebook.onVoteCanceled(defaultAcc, defaultAcc, 1);
            await votebook.onVoteCanceled(defaultAcc, otherAcc, 2);
            await votebook.onVoteCanceled(otherAcc, defaultAcc, 3);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), []);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(0));
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, otherAcc), []);
            expect(await votebook.getVoteIndex.call(defaultAcc, otherAcc, 1)).to.be.bignumber.equal(new BN(0));
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, otherAcc), []);
            expect(await votebook.getVoteIndex.call(otherAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(0));
        }
    });

    it('checking votekeeper pruning outdated votes', async () => {
        const votebook = await VotesBookKeeper.new();
        const fakeGov = await FakeVoteRecounter.new();
        await votebook.initialize(defaultAcc, fakeGov.address, 1000);
        expect(await votebook.owner()).to.equal(defaultAcc);

        {
            await votebook.onVoted(defaultAcc, defaultAcc, 1);
            await votebook.onVoted(defaultAcc, defaultAcc, 2);
            await votebook.onVoted(defaultAcc, defaultAcc, 3);

            await fakeGov.reset(defaultAcc, defaultAcc);
            await votebook.recountVotes(defaultAcc, defaultAcc);
            expect(await fakeGov.failed.call()).to.equal(false);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), [ new BN(1), new BN(2), new BN(3) ]);
            arrayBNEqual(await fakeGov.getRecounted.call(), [ new BN(1), new BN(2), new BN(3) ]);

            await fakeGov.reset(defaultAcc, defaultAcc);
            await fakeGov.setOutdatedProposals([2]);
            await votebook.recountVotes(defaultAcc, defaultAcc);
            expect(await fakeGov.failed.call()).to.equal(false);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), [ new BN(1), new BN(3) ]);
            arrayBNEqual(await fakeGov.getRecounted.call(), [ new BN(1), new BN(3) ]);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(1));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 2)).to.be.bignumber.equal(new BN(0));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 3)).to.be.bignumber.equal(new BN(2));

            await fakeGov.reset(defaultAcc, defaultAcc);
            await fakeGov.setOutdatedProposals([1, 3]);
            await votebook.recountVotes(defaultAcc, defaultAcc);
            expect(await fakeGov.failed.call()).to.equal(false);
            arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), []);
            arrayBNEqual(await fakeGov.getRecounted.call(), []);
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(0));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 2)).to.be.bignumber.equal(new BN(0));
            expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 3)).to.be.bignumber.equal(new BN(0));
        }
    });

    it('checking votekeeper proposals cap', async () => {
        const votebook = await VotesBookKeeper.new();
        const fakeGov = await FakeVoteRecounter.new();
        await votebook.initialize(defaultAcc, fakeGov.address, 1);
        expect(await votebook.owner()).to.equal(defaultAcc);

        await fakeGov.reset(defaultAcc, defaultAcc);
        await votebook.onVoted(defaultAcc, defaultAcc, 1);
        await expectRevert(votebook.onVoted(defaultAcc, defaultAcc, 2), 'too many votes');
        await votebook.onVoted(defaultAcc, defaultAcc, 1);
        await votebook.setMaxProposalsPerVoter(2);
        await votebook.onVoted(defaultAcc, defaultAcc, 2);
        await expectRevert(votebook.onVoted(defaultAcc, defaultAcc, 3), 'too many votes');

        await fakeGov.reset(defaultAcc, defaultAcc);
        await fakeGov.setOutdatedProposals([2]);
        await votebook.onVoted(defaultAcc, defaultAcc, 3);

        expect(await fakeGov.failed.call()).to.equal(false);
        arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), [ new BN(1), new BN(3) ]);
        arrayBNEqual(await fakeGov.getRecounted.call(), [ new BN(1) ]);
        expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(1));
        expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 2)).to.be.bignumber.equal(new BN(0));
        expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 3)).to.be.bignumber.equal(new BN(2));

        await fakeGov.reset(defaultAcc, defaultAcc);
        await fakeGov.setOutdatedProposals([1]);
        await votebook.onVoted(defaultAcc, defaultAcc, 2);

        expect(await fakeGov.failed.call()).to.equal(false);
        arrayBNEqual(await votebook.getProposalIDs.call(defaultAcc, defaultAcc), [ new BN(3), new BN(2) ]);
        arrayBNEqual(await fakeGov.getRecounted.call(), [ new BN(3) ]);
        expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 1)).to.be.bignumber.equal(new BN(0));
        expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 2)).to.be.bignumber.equal(new BN(2));
        expect(await votebook.getVoteIndex.call(defaultAcc, defaultAcc, 3)).to.be.bignumber.equal(new BN(1));
    });
});

contract('Governance test', async ([defaultAcc, otherAcc, firstVoterAcc, secondVoterAcc, delegatorAcc]) => {
    beforeEach(async () => {
        this.govable = await UnitTestGovernable.new();
        this.verifier = await ProposalTemplates.new();
        await this.verifier.initialize();
        this.votebook = await VotesBookKeeper.new();
        this.gov = await Governance.new();
        await this.votebook.initialize(defaultAcc, this.gov.address, 1000);
        await this.gov.initialize(this.govable.address, this.verifier.address, this.votebook.address);
        this.proposalFee = await this.gov.proposalFee();
        this.sfc = await UnitTestMockSFC.new({from: defaultAcc});
        this.factory = await NetworkParameterProposalFactory.new(this.gov.address, this.sfc.address);

        await this.sfc.initialize(defaultAcc, this.gov.address, {from: defaultAcc});
        await this.sfc.setMinSelfStake(new BN('500000'), {from: defaultAcc});
        await this.sfc.setMaxDelegation(new BN('16'), {from: defaultAcc});
        await this.sfc.setValidatorCommission(new BN('15'), {from: defaultAcc});
        await this.sfc.setContractCommission(new BN('30'), {from: defaultAcc});
        await this.sfc.setUnlockedRewardRatio(new BN('30'), {from: defaultAcc});
        await this.sfc.setMaxLockupDuration(new BN('86400'), {from: defaultAcc});
        await this.sfc.setWithdrawalPeriodEpoch(new BN('3'), {from: defaultAcc});
    });

    const scales = [0, 2, 3, 4, 5];

    it('checking deployment of a plaintext proposal contract', async () => {
        await this.verifier.addTemplate(1, 'plaintext', emptyAddr, NonExecutableType, ratio('0.4'), ratio('0.6'), [0, 1, 2, 3, 4], 120, 1200, 0, 60);
        const option = web3.utils.fromAscii('option');
        await expectRevert(PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.4'), ratio('0.6'), 0, 120, 1201, this.verifier.address), 'failed verification');
        await expectRevert(PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.4'), ratio('0.6'), 0, 119, 1201, this.verifier.address), 'failed verification');
        await expectRevert(PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.4'), ratio('0.6'), 61, 119, 1201, this.verifier.address), 'failed verification');
        await expectRevert(PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.4'), ratio('0.6'), 0, 501, 500, this.verifier.address), 'failed verification');
        await expectRevert(PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.399'), ratio('0.6'), 0, 501, 500, this.verifier.address), 'failed verification');
        await expectRevert(PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('1.01'), ratio('0.6'), 0, 501, 500, this.verifier.address), 'failed verification');
        await expectRevert(PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.4'), ratio('0.599'), 60, 120, 1200, this.verifier.address), 'failed verification');
        await expectRevert(PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.4'), ratio('1.01'), 60, 120, 1200, this.verifier.address), 'failed verification');
        await PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.4'), ratio('0.6'), 60, 120, 1200, this.verifier.address);
        await PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.4'), ratio('0.6'), 0, 1200, 1200, this.verifier.address);
        await PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.4'), ratio('0.6'), 0, 120, 120, this.verifier.address);
        await PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.4'), ratio('0.6'), 0, 120, 1200, this.verifier.address);
        await PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('1.0'), ratio('0.6'), 0, 120, 1200, this.verifier.address);
        await PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.5'), ratio('0.6'), 30, 121, 1199, this.verifier.address);
        await PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.5'), ratio('0.8'), 30, 121, 1199, this.verifier.address);
    });

    it('checking creation of a plaintext proposal', async () => {
        const pType = new BN(1);
        const now = await time.latest();
        await this.verifier.addTemplate(pType, 'plaintext', emptyAddr, NonExecutableType, ratio('0.4'), ratio('0.6'), [0, 1, 2, 3, 4], 120, 1200, 0, 60);
        const option = web3.utils.fromAscii('option');
        const emptyOptions = await PlainTextProposal.new('plaintext', 'plaintext-descr', [], ratio('0.5'), ratio('0.6'), 30, 121, 1199, this.verifier.address);
        const tooManyOptions = await PlainTextProposal.new('plaintext', 'plaintext-descr', [option, option, option, option, option, option, option, option, option, option, option], ratio('0.5'), ratio('0.6'), 30, 121, 1199, this.verifier.address);
        const wrongVotes = await PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.3'), ratio('0.6'), 30, 121, 1199, emptyAddr);
        const manyOptions = await PlainTextProposal.new('plaintext', 'plaintext-descr', [option, option, option, option, option, option, option, option, option, option], ratio('0.5'), ratio('0.6'), 30, 121, 1199, this.verifier.address);
        const oneOption = await PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.51'), ratio('0.6'), 30, 122, 1198, this.verifier.address);

        await expectRevert(this.gov.createProposal(emptyOptions.address, {value: this.proposalFee}), 'proposal options are empty - nothing to vote for');
        await expectRevert(this.gov.createProposal(tooManyOptions.address, {value: this.proposalFee}), 'too many options');
        await expectRevert(this.gov.createProposal(wrongVotes.address, {value: this.proposalFee}), 'proposal parameters failed verification');
        await expectRevert(this.gov.createProposal(manyOptions.address), 'paid proposal fee is wrong');
        await expectRevert(this.gov.createProposal(manyOptions.address, {value: this.proposalFee.add(new BN(1))}), 'paid proposal fee is wrong');
        await this.gov.createProposal(manyOptions.address, {value: this.proposalFee});
        await this.gov.createProposal(oneOption.address, {value: this.proposalFee});

        const infoManyOptions = await this.gov.proposalParams(1);
        expect(infoManyOptions.pType).to.be.bignumber.equal(pType);
        expect(infoManyOptions.executable).to.be.bignumber.equal(NonExecutableType);
        expect(infoManyOptions.minVotes).to.be.bignumber.equal(ratio('0.5'));
        expect(infoManyOptions.proposalContract).to.equal(manyOptions.address);
        expect(infoManyOptions.options.length).to.equal(10);
        expect(infoManyOptions.options[0]).to.equal('0x6f7074696f6e0000000000000000000000000000000000000000000000000000');
        expect(infoManyOptions.votingStartTime).to.be.bignumber.least(now);
        expect(infoManyOptions.votingMinEndTime).to.be.bignumber.equal(infoManyOptions.votingStartTime.add(new BN(121)));
        expect(infoManyOptions.votingMaxEndTime).to.be.bignumber.equal(infoManyOptions.votingStartTime.add(new BN(1199)));
        const infoOneOption = await this.gov.proposalParams(2);
        expect(infoOneOption.pType).to.be.bignumber.equal(pType);
        expect(infoOneOption.executable).to.be.bignumber.equal(NonExecutableType);
        expect(infoOneOption.minVotes).to.be.bignumber.equal(ratio('0.51'));
        expect(infoOneOption.proposalContract).to.equal(oneOption.address);
        expect(infoOneOption.options.length).to.equal(1);
        expect(infoOneOption.votingStartTime).to.be.bignumber.least(now);
        expect(infoOneOption.votingMinEndTime).to.be.bignumber.equal(infoOneOption.votingStartTime.add(new BN(122)));
        expect(infoOneOption.votingMaxEndTime).to.be.bignumber.equal(infoOneOption.votingStartTime.add(new BN(1198)));
    });

    it('checking creation with a factory', async () => {
        const pType = new BN(1);
        const plaintextFactory = await PlainTextProposalFactory.new(this.gov.address);
        await this.verifier.addTemplate(pType, 'plaintext', plaintextFactory.address, NonExecutableType, ratio('0.4'), ratio('0.6'), [0, 1, 2, 3, 4], 120, 1200, 30, 30);
        const option = web3.utils.fromAscii('option');

        await plaintextFactory.create('plaintext', 'plaintext-descr', [option], ratio('0.4'), ratio('0.6'), 30, 120, 1200, {from: otherAcc, value: this.proposalFee});
        const proposalID = await this.gov.lastProposalID();
        const proposalParams = await this.gov.proposalParams(proposalID);
        const proposal = await PlainTextProposal.at(proposalParams.proposalContract);
        expect(await proposal.owner()).to.equal(otherAcc);
        expect(await proposal.name()).to.equal('plaintext');
        expect(await proposal.description()).to.equal('plaintext-descr');

        const externalProposal = await PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.5'), ratio('0.6'), 30, 121, 1199, this.verifier.address);
        await expectRevert(this.gov.createProposal(externalProposal.address, {value: this.proposalFee}), 'proposal contract failed verification');
    })

    it('checking proposal verification with explicit timestamps and opinions', async () => {
        // check code which can be checked only by explicitly setting timestamps and opinions
        const pType = 999; // non-standard proposal type
        await this.verifier.addTemplate(pType, 'custom', emptyAddr, DelegatecallType, ratio('0.4'), ratio('0.6'), scales, 1000, 10000, 400, 2000);
        const now = await time.latest();
        const start = now.add(new BN(500));
        const minEnd = start.add(new BN(1000));
        const maxEnd = minEnd.add(new BN(1000));

        const proposal = await ExplicitProposal.new();
        await proposal.setType(pType);
        await proposal.setMinVotes(ratio('0.4'));
        await proposal.setMinAgreement(ratio('0.6'));
        await proposal.setOpinionScales(scales);
        await proposal.setVotingStartTime(start);
        await proposal.setVotingMinEndTime(minEnd);
        await proposal.setVotingMaxEndTime(maxEnd);
        await proposal.setExecutable(DelegatecallType);
        expect(await proposal.verifyProposalParams.call(this.verifier.address)).to.equal(true);

        await proposal.setVotingStartTime(now.sub(new BN(10))); // starts in past
        expect(await proposal.verifyProposalParams.call(this.verifier.address)).to.equal(false);
        await proposal.setVotingStartTime(start);

        await proposal.setVotingMinEndTime(start.sub(new BN(1))); // may end before the start
        expect(await proposal.verifyProposalParams.call(this.verifier.address)).to.equal(false);
        await proposal.setVotingMinEndTime(minEnd);

        await proposal.setVotingMaxEndTime(start.sub(new BN(1))); // must end before the start
        expect(await proposal.verifyProposalParams.call(this.verifier.address)).to.equal(false);
        await proposal.setVotingMaxEndTime(maxEnd);

        await proposal.setVotingMaxEndTime(minEnd.sub(new BN(1))); // min > max
        expect(await proposal.verifyProposalParams.call(this.verifier.address)).to.equal(false);
        await proposal.setVotingMaxEndTime(maxEnd);

        await proposal.setType(pType - 1); // wrong type
        expect(await proposal.verifyProposalParams.call(this.verifier.address)).to.equal(false);
        await proposal.setType(pType);

        await proposal.setOpinionScales([]); // wrong scales
        expect(await proposal.verifyProposalParams.call(this.verifier.address)).to.equal(false);
        await proposal.setOpinionScales([1]); // wrong scales
        expect(await proposal.verifyProposalParams.call(this.verifier.address)).to.equal(false);
        await proposal.setOpinionScales([1, 2, 3, 4, 5]); // wrong scales
        expect(await proposal.verifyProposalParams.call(this.verifier.address)).to.equal(false);
        await proposal.setOpinionScales(scales);

        expect(await proposal.verifyProposalParams.call(this.verifier.address)).to.equal(true);
    });

    const createProposal = async (_exec, optionsNum, minVotes, minAgreement, startDelay = 0, minEnd = 120, maxEnd = 1200, _scales = scales) => {
        if (await this.verifier.exists(15) === false) {
            await this.verifier.addTemplate(15, 'ExecLoggingProposal', emptyAddr, _exec, ratio('0.0'), ratio('0.0'), _scales, 0, 100000000, 0, 100000000);
        }
        const option = web3.utils.fromAscii('option');
        const options = [];
        for (let i = 0; i < optionsNum; i++) {
            options.push(option);
        }
        const contract = await ExecLoggingProposal.new('logger', 'logger-descr', options, minVotes, minAgreement, startDelay, minEnd, maxEnd, emptyAddr);
        await contract.setOpinionScales(_scales);
        await contract.setExecutable(_exec);

        await this.gov.createProposal(contract.address, {value: this.proposalFee});

        return {proposalID: await this.gov.lastProposalID(), proposal: contract};
    };
  
    const createNetworkParameterProposalViaFactory = async (optionsList, _exec, optionsNum, minVotes, minAgreement, startDelay = 0, minEnd = 120,  _signature, maxEnd = 1200, _scales = scales) => {
      if (await this.verifier.exists(15) === false) {
          await this.verifier.addTemplate(15, 'NetworkParameterProposal', emptyAddr, _exec, ratio('0.0'), ratio('0.0'), _scales, 0, 100000000, 0, 100000000);
      }
      const option = web3.utils.fromAscii('99999');
      const options = [];
      for (let i = 0; i < optionsNum; i++) {
          options.push(option);
      }
      const _strings = ['network', 'network-descr']
      const functionSignature = _signature;
      const _params = [minVotes, minAgreement, startDelay, minEnd, maxEnd]
      await this.factory.create(_strings, functionSignature, options, _params, optionsList, _exec, this.verifier.address, {value: this.proposalFee, from: defaultAcc});
      const contract = await this.factory.lastNetworkProposal();
  
      return {proposalID: await this.gov.lastProposalID(), proposal: contract};
  };

  it('checking creation of multiple network parameter proposals and their execution via proposal factory', async () => {
    const optionsNum = 1; // use maximum number of options to test gas usage
    const choices = [new BN(4)];
    const optionsList = [new BN(99999)];
    const maxDelegationProposal = await createNetworkParameterProposalViaFactory(optionsList, DelegatecallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120, MAX_DELEGATION);
    const validatorCommissionFeeProposal = await createNetworkParameterProposalViaFactory(optionsList, DelegatecallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120, VALIDATOR_COMMISSION_FEE);
    const contractCommissionFeeProposal = await createNetworkParameterProposalViaFactory(optionsList, DelegatecallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120, CONTRACT_COMMISSION_FEE);
    const unlockedRewardProposal = await createNetworkParameterProposalViaFactory(optionsList, DelegatecallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120, UNLOCKED_REWARD);
    const minLockupProposal = await createNetworkParameterProposalViaFactory(optionsList, DelegatecallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120, MIN_LOCKUP);
    const maxLockupProposal = await createNetworkParameterProposalViaFactory(optionsList, DelegatecallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120, MAX_LOCKUP);
    const withdrawalPeriodEpochValueProposal = await createNetworkParameterProposalViaFactory(optionsList, DelegatecallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120, WITHDRAWAL_PERIOD_EPOCH_VALUE);
    const withdrawalPeriodTimeValueProposal = await createNetworkParameterProposalViaFactory(optionsList, DelegatecallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120, WITHDRAWAL_PERIOD_TIME_VALUE);
    const minSelfStakeProposal = await createNetworkParameterProposalViaFactory(optionsList, DelegatecallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120, MIN_SELF_STAKE);

    const { proposalID: proposalIdOne } = maxDelegationProposal;
    const { proposalID: proposalIdTwo } = validatorCommissionFeeProposal;
    const { proposalID: proposalIdThree } = contractCommissionFeeProposal;
    const { proposalID: proposalIdFour } = unlockedRewardProposal;
    const { proposalID: proposalIdFive } = minLockupProposal;
    const { proposalID: proposalIdSix } = maxLockupProposal;
    const { proposalID: proposalIdSeven } = withdrawalPeriodEpochValueProposal;
    const { proposalID: proposalIdEight } = withdrawalPeriodTimeValueProposal;
    const { proposalID: proposalIdNine } = minSelfStakeProposal;
    // make new vote
    await this.govable.stake(defaultAcc, ether('10.0'));

    await this.gov.vote(defaultAcc, proposalIdOne, choices);
    await this.gov.vote(defaultAcc, proposalIdTwo, choices);
    await this.gov.vote(defaultAcc, proposalIdThree, choices);
    await this.gov.vote(defaultAcc, proposalIdFour, choices);
    await this.gov.vote(defaultAcc, proposalIdFive, choices);
    await this.gov.vote(defaultAcc, proposalIdSix, choices);
    await this.gov.vote(defaultAcc, proposalIdSeven, choices);
    await this.gov.vote(defaultAcc, proposalIdEight, choices);
    await this.gov.vote(defaultAcc, proposalIdNine, choices);

    // finalize voting by handling its task
    evm.advanceTime(120); // wait until min voting end time

    await this.gov.handleTasks(0, 1);
    await this.gov.handleTasks(1, 1);
    await this.gov.handleTasks(2, 1);
    await this.gov.handleTasks(3, 1);
    await this.gov.handleTasks(4, 1);
    await this.gov.handleTasks(5, 1);
    await this.gov.handleTasks(6, 1);
    await this.gov.handleTasks(7, 1);
    await this.gov.handleTasks(8, 1);

    expect((await this.sfc.maxDelegatedRatio()).toString()).to.equals('99999000000000000000000');
    expect((await this.sfc.minStakeAmnt()).toString()).to.equals('99999');
    expect((await this.sfc.validatorCommission()).toString()).to.equals('999990000000000000000');
    expect((await this.sfc.contractCommission()).toString()).to.equals('999990000000000000000');
    expect((await this.sfc.unlockedRewardRatio()).toString()).to.equals('999990000000000000000');
    expect((await this.sfc.minLockupDuration()).toString()).to.equals('1399986');
    expect((await this.sfc.maxLockupDuration()).toString()).to.equals('36499635');
    expect((await this.sfc.withdrawalPeriodEpochs()).toString()).to.equals('99999');
    expect((await this.sfc.withdrawalPeriodTime()).toString()).to.equals('99999');
});

    it('checking self-vote creation', async () => {
        const optionsNum = 3;
        const choices = [new BN(0), new BN(3), new BN(4)];
        const proposalInfo = await createProposal(NonExecutableType, optionsNum, ratio('0.5'), ratio('0.6'), 60);
        const proposalID = proposalInfo.proposalID;
        // make new vote
        await expectRevert(this.gov.vote(defaultAcc, proposalID, choices), "proposal voting has't begun");
        time.increase(60);
        await expectRevert(this.gov.vote(defaultAcc, proposalID, choices), 'zero weight');
        await this.govable.stake(defaultAcc, ether('10.0'));
        await expectRevert(this.gov.vote(defaultAcc, proposalID.add(new BN(1)), choices), 'proposal with a given ID doesnt exist');
        await expectRevert(this.gov.vote(defaultAcc, proposalID, [new BN(3), new BN(4)]), 'wrong number of choices');
        await expectRevert(this.gov.vote(defaultAcc, proposalID, [new BN(5), new BN(3), new BN(4)]), 'wrong opinion ID');
        await this.gov.vote(defaultAcc, proposalID, choices);
        await expectRevert(this.gov.vote(defaultAcc, proposalID, [new BN(1), new BN(3), new BN(4)]), 'vote already exists');
    });

    describe('checking votes for a self-voter', async () => {
        const optionsNum = 3;
        const choices = [new BN(0), new BN(3), new BN(4)];
        let proposalID = 0;
        beforeEach('create vote', async () => {
            const proposalInfo = await createProposal(NonExecutableType, optionsNum, ratio('0.5'), ratio('0.6'), 60);
            proposalID = proposalInfo.proposalID;
            // make new vote
            time.increase(60);
            await this.govable.stake(defaultAcc, ether('10.0'));
            await this.gov.vote(defaultAcc, proposalID, choices);
        });

        it('checking voting state', async () => {
            await this.govable.stake(defaultAcc, ether('5.0'));
            // check
            const proposalStateInfo = await this.gov.proposalState(proposalID);
            expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
            expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('10.0'));
            expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(0));
            const option0 = await this.gov.proposalOptionState(proposalID, 0);
            const option1 = await this.gov.proposalOptionState(proposalID, 1);
            const option2 = await this.gov.proposalOptionState(proposalID, 2);
            expect(option0.votes).to.be.bignumber.equal(ether('10.0'));
            expect(option1.votes).to.be.bignumber.equal(ether('10.0'));
            expect(option2.votes).to.be.bignumber.equal(ether('10.0'));
            expect(option0.agreement).to.be.bignumber.equal(ether('0.0'));
            expect(option1.agreement).to.be.bignumber.equal(ether('8.0'));
            expect(option2.agreement).to.be.bignumber.equal(ether('10.0'));
            expect(option0.agreementRatio).to.be.bignumber.equal(ratio('0.0'));
            expect(option1.agreementRatio).to.be.bignumber.equal(ratio('0.8'));
            expect(option2.agreementRatio).to.be.bignumber.equal(ratio('1.0'));
            const votingInfo = await this.gov.calculateVotingTally(proposalID);
            expect(votingInfo.proposalResolved).to.equal(true);
            expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(2)); // option with a best opinion
            expect(votingInfo.votes).to.be.bignumber.equal(ether('10.0'));
            // clean up
            await this.gov.cancelVote(defaultAcc, proposalID);
        });

        it('cancel vote', async () => {
            await expectRevert(this.gov.cancelVote(defaultAcc, proposalID.add(new BN(1))), "doesn't exist");
            await expectRevert(this.gov.cancelVote(otherAcc, proposalID), "doesn't exist");
            await this.gov.cancelVote(defaultAcc, proposalID);
            // vote should be erased, checked by afterEach
        });

        it('recount vote', async () => {
            await this.govable.stake(defaultAcc, ether('5.0'));
            await expectRevert(this.gov.recountVote(otherAcc, defaultAcc, proposalID, {from: otherAcc}), "doesn't exist");
            await expectRevert(this.gov.recountVote(defaultAcc, otherAcc, proposalID, {from: otherAcc}), "doesn't exist");
            await this.gov.recountVote(defaultAcc, defaultAcc, proposalID, {from: otherAcc}); // anyone can send
            await expectRevert(this.gov.recountVote(defaultAcc, defaultAcc, proposalID, {from: otherAcc}), 'nothing changed');
            // check
            const proposalStateInfo = await this.gov.proposalState(proposalID);
            expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
            expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('15.0'));
            expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(0));
            const option0 = await this.gov.proposalOptionState(proposalID, 0);
            const option1 = await this.gov.proposalOptionState(proposalID, 1);
            const option2 = await this.gov.proposalOptionState(proposalID, 2);
            expect(option0.votes).to.be.bignumber.equal(ether('15.0'));
            expect(option1.votes).to.be.bignumber.equal(ether('15.0'));
            expect(option2.votes).to.be.bignumber.equal(ether('15.0'));
            expect(option0.agreement).to.be.bignumber.equal(ether('0.0'));
            expect(option1.agreement).to.be.bignumber.equal(ether('12.0'));
            expect(option2.agreement).to.be.bignumber.equal(ether('15.0'));
            expect(option0.agreementRatio).to.be.bignumber.equal(ratio('0.0'));
            expect(option1.agreementRatio).to.be.bignumber.equal(ratio('0.8'));
            expect(option2.agreementRatio).to.be.bignumber.equal(ratio('1.0'));
            const votingInfo = await this.gov.calculateVotingTally(proposalID);
            expect(votingInfo.proposalResolved).to.equal(true);
            expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(2)); // option with a best opinion
            expect(votingInfo.votes).to.be.bignumber.equal(ether('15.0'));
            // clean up
            await this.gov.cancelVote(defaultAcc, proposalID);
        });

        it('cancel vote via recounting', async () => {
            this.govable.unstake(defaultAcc, ether('10.0'));
            await this.gov.recountVote(defaultAcc, defaultAcc, proposalID, {from: otherAcc});
            await expectRevert(this.gov.recountVote(defaultAcc, defaultAcc, proposalID, {from: otherAcc}), "doesn't exist");
            // vote should be erased, checked by afterEach
        });

        it('cancel vote via recounting from votebook', async () => {
            this.govable.unstake(defaultAcc, ether('10.0'));
            await this.votebook.recountVotes(defaultAcc, defaultAcc, {from: otherAcc});
            arrayBNEqual(await this.votebook.getProposalIDs.call(defaultAcc, defaultAcc), []);
            await expectRevert(this.gov.recountVote(defaultAcc, defaultAcc, proposalID, {from: otherAcc}), "doesn't exist");
            // vote should be erased, checked by afterEach
        });

        afterEach('checking state is empty', async () => {
            const proposalStateInfo = await this.gov.proposalState(proposalID);
            expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
            expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('0.0'));
            expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(0));
            const voteInfo = await this.gov.getVote(defaultAcc, defaultAcc, proposalID);
            expect(voteInfo.weight).to.be.bignumber.equal(ether('0.0'));
            expect(voteInfo.choices.length).to.equal(0);
            const option0 = await this.gov.proposalOptionState(proposalID, 0);
            const option2 = await this.gov.proposalOptionState(proposalID, 2);
            expect(option0.votes).to.be.bignumber.equal(ether('0.0'));
            expect(option2.votes).to.be.bignumber.equal(ether('0.0'));
            expect(option0.agreement).to.be.bignumber.equal(ether('0.0'));
            expect(option2.agreement).to.be.bignumber.equal(ether('0.0'));
            expect(option0.agreementRatio).to.be.bignumber.equal(ratio('0.0'));
            expect(option2.agreementRatio).to.be.bignumber.equal(ratio('0.0'));
            const votingInfo = await this.gov.calculateVotingTally(proposalID);
            expect(votingInfo.proposalResolved).to.equal(false);
            expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(optionsNum));
            expect(votingInfo.votes).to.be.bignumber.equal(ether('0.0'));
            await expectRevert(this.gov.handleTasks(0, 1), 'no tasks handled');
            await expectRevert(this.gov.tasksCleanup(1), 'no tasks erased');
        });
    });

    it('checking voting tally for a self-voter', async () => {
        const optionsNum = 10; // use maximum number of options to test gas usage
        const choices = [new BN(2), new BN(2), new BN(3), new BN(2), new BN(2), new BN(2), new BN(2), new BN(2), new BN(2), new BN(2)];
        const proposalInfo = await createProposal(DelegatecallType, optionsNum, ratio('0.5'), ratio('0.6'), 60, 120);
        const proposalID = proposalInfo.proposalID;
        const proposalContract = proposalInfo.proposal;
        // make new vote
        time.increase(60);
        await this.govable.stake(defaultAcc, ether('10.0'));
        await this.gov.vote(defaultAcc, proposalID, choices);

        // check proposal isn't executed
        expect(await proposalContract.executedCounter()).to.be.bignumber.equal(new BN(0));

        // check voting is ready to be finalized
        const votingInfo = await this.gov.calculateVotingTally(proposalID);
        expect(votingInfo.proposalResolved).to.equal(true);
        expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(2)); // option with a best opinion
        expect(votingInfo.votes).to.be.bignumber.equal(ether('10.0'));

        // finalize voting by handling its task
        const task = await this.gov.getTask(0);
        expect(await this.gov.tasksCount()).to.be.bignumber.equal(new BN(1));
        expect(task.active).to.equal(true);
        expect(task.assignment).to.be.bignumber.equal(new BN(1));
        expect(task.proposalID).to.be.bignumber.equal(proposalID);

        await expectRevert(this.gov.handleTasks(0, 1), 'no tasks handled');
        time.increase(120); // wait until min voting end time
        await expectRevert(this.gov.handleTasks(1, 1), 'no tasks handled');
        await this.gov.handleTasks(0, 1);
        await expectRevert(this.gov.handleTasks(0, 1), 'no tasks handled');

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(2));
        expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('10.0'));
        expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(1));

        // check proposal execution via delegatecall
        expect(await proposalContract.executedCounter()).to.be.bignumber.equal(new BN(1));
        expect(await proposalContract.executedMsgSender()).to.equal(defaultAcc);
        expect(await proposalContract.executedAs()).to.equal(this.gov.address);
        expect(await proposalContract.executedOption()).to.be.bignumber.equal(new BN(2));

        // try to cancel vote
        await expectRevert(this.gov.cancelVote(defaultAcc, proposalID), "proposal isn't active");

        // try to recount vote
        await this.govable.stake(defaultAcc, ether('5.0'));
        await expectRevert(this.gov.recountVote(defaultAcc, defaultAcc, proposalID, {from: otherAcc}), "proposal isn't active");

        // cleanup task
        const taskDeactivated = await this.gov.getTask(0);
        expect(await this.gov.tasksCount()).to.be.bignumber.equal(new BN(1));
        expect(taskDeactivated.active).to.equal(false);
        expect(taskDeactivated.assignment).to.be.bignumber.equal(new BN(1));
        expect(taskDeactivated.proposalID).to.be.bignumber.equal(proposalID);
        await expectRevert(this.gov.tasksCleanup(0), 'no tasks erased');
        await this.gov.tasksCleanup(10);
        expect(await this.gov.tasksCount()).to.be.bignumber.equal(new BN(0));
    });

    it('checking proposal execution via call', async () => {
        const optionsNum = 1; // use maximum number of options to test gas usage
        const choices = [new BN(4)];
        const proposalInfo = await createProposal(CallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120);
        const proposalID = proposalInfo.proposalID;
        const proposalContract = proposalInfo.proposal;
        // make new vote
        await this.govable.stake(defaultAcc, ether('10.0'));
        await this.gov.vote(defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        time.increase(120); // wait until min voting end time
        await this.gov.handleTasks(0, 1);

        // check proposal execution via call
        expect(await proposalContract.executedCounter()).to.be.bignumber.equal(new BN(1));
        expect(await proposalContract.executedMsgSender()).to.equal(this.gov.address);
        expect(await proposalContract.executedAs()).to.equal(proposalContract.address);
        expect(await proposalContract.executedOption()).to.be.bignumber.equal(new BN(0));
    });

    it('checking proposal execution via delegatecall', async () => {
        const optionsNum = 1;
        const choices = [new BN(4)];
        const proposalInfo = await createProposal(DelegatecallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120);
        const proposalID = proposalInfo.proposalID;
        const proposalContract = proposalInfo.proposal;
        // make new vote
        await this.govable.stake(defaultAcc, ether('10.0'));
        await this.gov.vote(defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        time.increase(120); // wait until min voting end time
        await this.gov.handleTasks(0, 1);

        // check proposal execution via delegatecall
        expect(await proposalContract.executedCounter()).to.be.bignumber.equal(new BN(1));
        expect(await proposalContract.executedMsgSender()).to.equal(defaultAcc);
        expect(await proposalContract.executedAs()).to.equal(this.gov.address);
        expect(await proposalContract.executedOption()).to.be.bignumber.equal(new BN(0));
    });

    it('checking non-executable proposal resolving', async () => {
        const optionsNum = 2;
        const choices = [new BN(0), new BN(4)];
        const proposalInfo = await createProposal(NonExecutableType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120);
        const proposalID = proposalInfo.proposalID;
        const proposalContract = proposalInfo.proposal;
        // make new vote
        await this.govable.stake(defaultAcc, ether('10.0'));
        await this.gov.vote(defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        time.increase(120); // wait until min voting end time
        await this.gov.handleTasks(0, 1);

        // check proposal execution via delegatecall
        expect(await proposalContract.executedCounter()).to.be.bignumber.equal(new BN(0));

        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(1));
        expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('10.0'));
        expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(1));
    });

    it('checking proposal rejecting before max voting end is reached', async () => {
        const optionsNum = 1; // use maximum number of options to test gas usage
        const choices = [new BN(0)];
        const proposalInfo = await createProposal(CallType, optionsNum, ratio('0.5'), ratio('0.6'), 0, 120, 240);
        const proposalID = proposalInfo.proposalID;
        const proposalContract = proposalInfo.proposal;
        // make new vote
        await this.govable.stake(defaultAcc, ether('10.0'));
        await this.gov.vote(defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        time.increase(120); // wait until min voting end time
        await this.gov.handleTasks(0, 1);

        // check proposal is rejected
        expect(await proposalContract.executedCounter()).to.be.bignumber.equal(new BN(0));
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
        expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('10.0'));
        expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(2));
    });

    it('checking voting tally with low turnout', async () => {
        const choices = [new BN(2)];
        const proposalInfo = await createProposal(NonExecutableType, 1, ratio('0.5'), ratio('0.6'), 60, 500, 1000);
        const proposalID = proposalInfo.proposalID;
        // make new vote
        time.increase(60 + 500 + 10);
        await this.govable.stake(defaultAcc, ether('10.0'));
        await this.gov.vote(defaultAcc, proposalID, choices);

        await this.govable.stake(defaultAcc, ether('10.1')); // turnout is less than 50% now, and maxEnd has occurred
        await expectRevert(this.gov.handleTasks(0, 1), 'no tasks handled');
        this.govable.unstake(defaultAcc, ether('0.1')); // turnout is exactly 50% now
        // finalize voting by handling its task
        await this.gov.handleTasks(0, 10);

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
        expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('10.0'));
        expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(1));
    });

    it('checking execution expiration', async () => {
        const choices = [new BN(2)];
        const proposalInfo = await createProposal(CallType, 1, ratio('0.5'), ratio('0.6'), 60, 500, 1000);
        const proposalID = proposalInfo.proposalID;
        const proposalContract = proposalInfo.proposal;
        const maxExecutionPeriod = await this.gov.maxExecutionPeriod();
        // make new vote
        time.increase(maxExecutionPeriod.add(new BN(60 + 1000 + 10)));
        await this.govable.stake(defaultAcc, ether('10.0'));
        await this.gov.vote(defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await this.gov.handleTasks(0, 10);

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
        expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('10.0'));
        expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(8));

        // check proposal isn't executed
        expect(await proposalContract.executedCounter()).to.be.bignumber.equal(new BN(0));
    });

    it('checking proposal is rejected if low agreement after max voting end', async () => {
        const choices = [new BN(1)];
        const proposalInfo = await createProposal(CallType, 1, ratio('0.5'), ratio('0.6'), 60, 500, 1000);
        const proposalID = proposalInfo.proposalID;
        const proposalContract = proposalInfo.proposal;
        const maxExecutionPeriod = await this.gov.maxExecutionPeriod();
        // make new vote
        time.increase(maxExecutionPeriod.add(new BN(60 + 1000 + 10)));
        this.govable.stake(defaultAcc, ether('10.0'));
        await this.gov.vote(defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await this.gov.handleTasks(0, 10);

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
        expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('10.0'));
        expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(2));

        // check proposal isn't executed
        expect(await proposalContract.executedCounter()).to.be.bignumber.equal(new BN(0));
    });

    it('checking proposal is rejected if low turnout after max voting end', async () => {
        const choices = [new BN(4)];
        const proposalInfo = await createProposal(CallType, 1, ratio('0.5'), ratio('0.6'), 60, 500, 1000);
        const proposalID = proposalInfo.proposalID;
        const proposalContract = proposalInfo.proposal;
        const maxExecutionPeriod = await this.gov.maxExecutionPeriod();
        // make new vote
        time.increase(maxExecutionPeriod.add(new BN(60 + 1000 + 10)));
        this.govable.stake(defaultAcc, ether('10.0')); // defaultAcc has less than 50% of weight
        this.govable.stake(firstVoterAcc, ether('11.0'));
        await this.gov.vote(defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await this.gov.handleTasks(0, 10);

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
        expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('10.0'));
        expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(2));

        // check proposal isn't executed
        expect(await proposalContract.executedCounter()).to.be.bignumber.equal(new BN(0));
    });

    it("checking execution doesn't expire earlier than needed", async () => {
        const choices = [new BN(2)];
        const proposalInfo = await createProposal(DelegatecallType, 1, ratio('0.5'), ratio('0.6'), 60, 500, 1000);
        const proposalID = proposalInfo.proposalID;
        const proposalContract = proposalInfo.proposal;
        const maxExecutionPeriod = await this.gov.maxExecutionPeriod();
        // make new vote
        time.increase(maxExecutionPeriod.add(new BN(60 + 1000 - 10)));
        await this.govable.stake(defaultAcc, ether('10.0'));
        await this.gov.vote(defaultAcc, proposalID, choices);

        // finalize voting by handling its task
        await this.gov.handleTasks(0, 10);

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
        expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('10.0'));
        expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(1));

        // check proposal is executed
        expect(await proposalContract.executedCounter()).to.be.bignumber.equal(new BN(1));
    });

    it("checking proposal cancellation", async () => {
        const choices = [new BN(2)];
        const proposalInfo = await createProposal(NonExecutableType, 1, ratio('0.5'), ratio('0.6'), 60, 500, 1000);
        const proposalID = proposalInfo.proposalID;
        const proposalContract = proposalInfo.proposal;
        const maxExecutionPeriod = await this.gov.maxExecutionPeriod();
        // make new vote
        time.increase(maxExecutionPeriod.add(new BN(60 + 1000 - 10)));
        await this.govable.stake(defaultAcc, ether('10.0'));
        await this.gov.vote(defaultAcc, proposalID, choices);

        // try to cancel proposal
        await expectRevert(this.gov.cancelProposal(proposalID.add(new BN(1))), 'proposal with a given ID doesnt exist');
        await expectRevert(this.gov.cancelProposal(proposalID), 'voting has already begun');
        await this.gov.cancelVote(defaultAcc, proposalID);
        await expectRevert(this.gov.cancelProposal(proposalID), 'must be sent from the proposal contract');
        await proposalContract.cancel(proposalID, this.gov.address);
        await expectRevert(this.gov.cancelProposal(proposalID), "proposal isn't active");
        await expectRevert(this.gov.vote(defaultAcc, proposalID, choices), "proposal isn't active");

        // check proposal status
        const proposalStateInfo = await this.gov.proposalState(proposalID);
        expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
        expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('0.0'));
        expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(4));

        // handle task
        await this.gov.handleTasks(0, 1);
        await this.gov.tasksCleanup(1);

        // check proposal status hasn't changed after the task
        const proposalStateInfoAfterTask = await this.gov.proposalState(proposalID);
        expect(proposalStateInfoAfterTask.winnerOptionID).to.be.bignumber.equal(new BN(0));
        expect(proposalStateInfoAfterTask.votes).to.be.bignumber.equal(ether('0.0'));
        expect(proposalStateInfoAfterTask.status).to.be.bignumber.equal(new BN(4));

        // check proposal isn't executed
        expect(await proposalContract.executedCounter()).to.be.bignumber.equal(new BN(0));
    });

    it("checking handling multiple tasks", async () => {
        await this.govable.stake(defaultAcc, ether('10.0'));
        // make 5 proposals which are ready for a finalization
        for (const i of [0, 1, 2, 3, 4]) {
            const choices = [new BN(2)];
            const proposalInfo = await createProposal(NonExecutableType, 1, ratio('0.5'), ratio('0.6'), 0, 500, 1000);
            const proposalID = proposalInfo.proposalID;
            // make a vote
            await this.gov.vote(defaultAcc, proposalID, choices);
        }
        time.increase(new BN(500 + 10));

        expect(await this.gov.tasksCount()).to.be.bignumber.equal(new BN(5));
        await this.gov.handleTasks(1, 3);
        for (const i of [1, 2, 3]) {
            const proposalID = i + 1;
            // check proposal status
            const proposalStateInfo = await this.gov.proposalState(proposalID);
            expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(1));
            // check task status
            const task = await this.gov.getTask(i);
            expect(task.active).to.equal(false);
        }
        for (const i of [0, 4]) {
            const proposalID = i + 1;
            // check proposal status
            const proposalStateInfo = await this.gov.proposalState(proposalID);
            expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(0));
            // check task status
            const task = await this.gov.getTask(i);
            expect(task.active).to.equal(true);
        }
        await expectRevert(this.gov.tasksCleanup(1), 'no tasks erased'); // last task is still active
        await this.gov.handleTasks(4, 1); // handle last task
        await expectRevert(this.gov.tasksCleanup(0), 'no tasks erased');
        await this.gov.tasksCleanup(1);
        expect(await this.gov.tasksCount()).to.be.bignumber.equal(new BN(4));
        await this.gov.tasksCleanup(4);
        expect(await this.gov.tasksCount()).to.be.bignumber.equal(new BN(1)); // first task is still active
        await expectRevert(this.gov.tasksCleanup(1), 'no tasks erased');
        await this.gov.handleTasks(0, 1); // handle first task
        await this.gov.tasksCleanup(1);
        expect(await this.gov.tasksCount()).to.be.bignumber.equal(new BN(0));
        for (const i of [0, 1, 2, 3, 4]) {
            const proposalID = i + 1;
            // check proposal status
            const proposalStateInfo = await this.gov.proposalState(proposalID);
            expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(1));
        }
    });

    it('checking delegation vote creation', async () => {
        const optionsNum = 3;
        const choices0 = [new BN(0), new BN(3), new BN(4)];
        const choices1 = [new BN(1), new BN(2), new BN(3)];
        const proposalInfo = await createProposal(NonExecutableType, optionsNum, ratio('0.5'), ratio('0.6'), 60);
        const proposalID = proposalInfo.proposalID;
        // make new vote
        time.increase(60);
        await this.govable.stake(firstVoterAcc, ether('10.0'), {from: firstVoterAcc});
        await this.gov.vote(firstVoterAcc, proposalID, choices0, {from: firstVoterAcc});
        await expectRevert(this.gov.vote(firstVoterAcc, proposalID, choices1, {from: delegatorAcc}), 'zero weight');
        await this.govable.stake(firstVoterAcc, ether('10.0'), {from: delegatorAcc});
        await expectRevert(this.gov.vote(delegatorAcc, proposalID, choices1, {from: delegatorAcc}), 'zero weight');
        await expectRevert(this.gov.vote(otherAcc, proposalID, choices1, {from: delegatorAcc}), 'zero weight');
        await expectRevert(this.gov.vote(delegatorAcc, proposalID, choices1, {from: firstVoterAcc}), 'zero weight');
        await expectRevert(this.gov.vote(firstVoterAcc, proposalID.add(new BN(1)), choices1), 'proposal with a given ID doesnt exist');
        await expectRevert(this.gov.vote(firstVoterAcc, proposalID, [new BN(3), new BN(4)], {from: delegatorAcc}), 'wrong number of choices');
        await expectRevert(this.gov.vote(firstVoterAcc, proposalID, [new BN(3), new BN(4), new BN(5)], {from: delegatorAcc}), 'wrong opinion ID');
        await this.gov.vote(firstVoterAcc, proposalID, choices1, {from: delegatorAcc});
        await expectRevert(this.gov.vote(firstVoterAcc, proposalID, [new BN(1), new BN(3), new BN(4)], {from: delegatorAcc}), 'vote already exists');
    });

    var votersAndDelegatorsTests = (delegatorFirst) => {
        return async () => {
            const optionsNum = 3;
            let proposalID = 0;
            beforeEach('create vote', async () => {
                await createProposal(NonExecutableType, optionsNum, ratio('0.5'), ratio('0.6'), 60);
                const proposalInfo = await createProposal(NonExecutableType, optionsNum, ratio('0.5'), ratio('0.6'), 60);
                proposalID = proposalInfo.proposalID;
                // make the new votes
                time.increase(60 + 10);
                if (delegatorFirst) {
                    await this.govable.stake(firstVoterAcc, ether('30.0'), {from: delegatorAcc});
                    await this.gov.vote(firstVoterAcc, proposalID, [new BN(1), new BN(2), new BN(3)], {from: delegatorAcc});
                }
                await this.govable.stake(firstVoterAcc, ether('10.0'), {from: firstVoterAcc});
                await this.gov.vote(firstVoterAcc, proposalID, [new BN(3), new BN(2), new BN(0)], {from: firstVoterAcc});
                await this.govable.stake(secondVoterAcc, ether('20.0'), {from: secondVoterAcc});
                await this.gov.vote(secondVoterAcc, proposalID, [new BN(2), new BN(3), new BN(4)], {from: secondVoterAcc});
                if (!delegatorFirst) {
                    await this.govable.stake(firstVoterAcc, ether('30.0'), {from: delegatorAcc});
                    await this.gov.vote(firstVoterAcc, proposalID, [new BN(1), new BN(2), new BN(3)], {from: delegatorAcc});
                }
            });

            const checkFullVotes = async () => {
                const voteInfo1 = await this.gov.getVote(firstVoterAcc, firstVoterAcc, proposalID);
                expect(voteInfo1.weight).to.be.bignumber.equal(ether('10.0'));
                expect(voteInfo1.choices.length).to.equal(3);
                const voteInfo2 = await this.gov.getVote(secondVoterAcc, secondVoterAcc, proposalID);
                expect(voteInfo2.weight).to.be.bignumber.equal(ether('20.0'));
                expect(voteInfo2.choices.length).to.equal(3);
                const voteInfo3 = await this.gov.getVote(delegatorAcc, firstVoterAcc, proposalID);
                expect(voteInfo3.weight).to.be.bignumber.equal(ether('30.0'));
                expect(voteInfo3.choices.length).to.equal(3);
                const voteInfo4 = await this.gov.getVote(firstVoterAcc, delegatorAcc, proposalID);
                expect(voteInfo4.weight).to.be.bignumber.equal(ether('0.0'));
                expect(voteInfo4.choices.length).to.equal(0);
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID.sub(new BN(1)))).to.be.bignumber.equal(ether('0.0'));
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID)).to.be.bignumber.equal(ether('30.0'));
                const proposalStateInfo = await this.gov.proposalState(proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
                expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('60.0'));
                expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(0));
                const option0 = await this.gov.proposalOptionState(proposalID, 0);
                const option1 = await this.gov.proposalOptionState(proposalID, 1);
                const option2 = await this.gov.proposalOptionState(proposalID, 2);
                expect(option0.votes).to.be.bignumber.equal(ether('60.0'));
                expect(option1.votes).to.be.bignumber.equal(ether('60.0'));
                expect(option2.votes).to.be.bignumber.equal(ether('60.0'));
                expect(option0.agreement).to.be.bignumber.equal(ether('32'));
                expect(option1.agreement).to.be.bignumber.equal(ether('40'));
                expect(option2.agreement).to.be.bignumber.equal(ether('44'));
                expect(option0.agreementRatio).to.be.bignumber.equal(ratio('0.533333333333333333'));
                expect(option1.agreementRatio).to.be.bignumber.equal(ratio('0.666666666666666666'));
                expect(option2.agreementRatio).to.be.bignumber.equal(ratio('0.733333333333333333'));
                const votingInfo = await this.gov.calculateVotingTally(proposalID);
                expect(votingInfo.proposalResolved).to.equal(true);
                expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(2)); // option with a best opinion
                expect(votingInfo.votes).to.be.bignumber.equal(ether('60.0'));
            };

            it('cancel votes', async () => {
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID)).to.be.bignumber.equal(ether('30.0'));
                const votingInfoAfter = await this.gov.calculateVotingTally(proposalID);
                expect(votingInfoAfter.votes).to.be.bignumber.equal(ether('30.0'));
                expect(votingInfoAfter.proposalResolved).to.equal(true);
                expect(votingInfoAfter.winnerID).to.be.bignumber.equal(new BN(2)); // option with a best opinion
                await expectRevert(this.gov.cancelVote(firstVoterAcc, proposalID.add(new BN(1)), {from: delegatorAcc}), "doesn't exist");
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
            });

            it('cancel votes in reversed order', async () => {
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
            });

            it('checking voting state', async () => {
                // check
                await checkFullVotes();
                // clean up
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
            });

            it('checking voting state after delegator re-voting', async () => {
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
                await expectRevert(this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc}), "doesn't exist");
                await this.gov.vote(firstVoterAcc, proposalID, [new BN(1), new BN(2), new BN(3)], {from: delegatorAcc});
                // check
                await checkFullVotes();
                // clean up
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
            });

            it('checking voting state after first voter re-voting', async () => {
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
                await expectRevert(this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc}), "doesn't exist");
                await this.gov.vote(firstVoterAcc, proposalID, [new BN(3), new BN(2), new BN(0)], {from: firstVoterAcc});
                // check
                await checkFullVotes();
                // clean up
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
            });

            it('checking voting state after second voter re-voting', async () => {
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
                await expectRevert(this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc}), "doesn't exist");
                await this.gov.vote(secondVoterAcc, proposalID, [new BN(2), new BN(3), new BN(4)], {from: secondVoterAcc});
                // check
                await checkFullVotes();
                // clean up
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
            });

            it('checking voting state after delegator vote canceling', async () => {
                // cancel delegator vote
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
                // check
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID.sub(new BN(1)))).to.be.bignumber.equal(ether('0.0'));
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID)).to.be.bignumber.equal(ether('0.0'));
                const proposalStateInfo = await this.gov.proposalState(proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
                expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('60.0'));
                expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(0));
                const option0 = await this.gov.proposalOptionState(proposalID, 0);
                const option1 = await this.gov.proposalOptionState(proposalID, 1);
                const option2 = await this.gov.proposalOptionState(proposalID, 2);
                expect(option0.votes).to.be.bignumber.equal(ether('60.0'));
                expect(option1.votes).to.be.bignumber.equal(ether('60.0'));
                expect(option2.votes).to.be.bignumber.equal(ether('60.0'));
                expect(option0.agreement).to.be.bignumber.equal(ether('44'));
                expect(option1.agreement).to.be.bignumber.equal(ether('40'));
                expect(option2.agreement).to.be.bignumber.equal(ether('20'));
                expect(option0.agreementRatio).to.be.bignumber.equal(ratio('0.733333333333333333'));
                expect(option1.agreementRatio).to.be.bignumber.equal(ratio('0.666666666666666666'));
                expect(option2.agreementRatio).to.be.bignumber.equal(ratio('0.333333333333333333'));
                const votingInfo = await this.gov.calculateVotingTally(proposalID);
                expect(votingInfo.proposalResolved).to.equal(true);
                expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(0)); // option with a best opinion
                expect(votingInfo.votes).to.be.bignumber.equal(ether('60.0'));
                // clean up
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
            });

            it('checking voting state after first staker vote canceling', async () => {
                // cancel first voter vote
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
                // check
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID.sub(new BN(1)))).to.be.bignumber.equal(ether('0.0'));
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID)).to.be.bignumber.equal(ether('30.0'));
                const proposalStateInfo = await this.gov.proposalState(proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
                expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('50.0'));
                expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(0));
                const option0 = await this.gov.proposalOptionState(proposalID, 0);
                const option1 = await this.gov.proposalOptionState(proposalID, 1);
                const option2 = await this.gov.proposalOptionState(proposalID, 2);
                expect(option0.votes).to.be.bignumber.equal(ether('50.0'));
                expect(option1.votes).to.be.bignumber.equal(ether('50.0'));
                expect(option2.votes).to.be.bignumber.equal(ether('50.0'));
                expect(option0.agreement).to.be.bignumber.equal(ether('24'));
                expect(option1.agreement).to.be.bignumber.equal(ether('34'));
                expect(option2.agreement).to.be.bignumber.equal(ether('44'));
                expect(option0.agreementRatio).to.be.bignumber.equal(ratio('0.48'));
                expect(option1.agreementRatio).to.be.bignumber.equal(ratio('0.68'));
                expect(option2.agreementRatio).to.be.bignumber.equal(ratio('0.88'));
                const votingInfo = await this.gov.calculateVotingTally(proposalID);
                expect(votingInfo.proposalResolved).to.equal(true);
                expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(2)); // option with a best opinion
                expect(votingInfo.votes).to.be.bignumber.equal(ether('50.0'));
                // clean up
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
            });

            it('checking voting state after delegator recounting', async () => {
                this.govable.unstake(firstVoterAcc, ether('5.0'), {from: delegatorAcc});
                await this.gov.recountVote(delegatorAcc, firstVoterAcc, proposalID, {from: otherAcc});
                // check
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID.sub(new BN(1)))).to.be.bignumber.equal(ether('0.0'));
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID)).to.be.bignumber.equal(ether('25.0'));
                const proposalStateInfo = await this.gov.proposalState(proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
                expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('55.0'));
                expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(0));
                const option0 = await this.gov.proposalOptionState(proposalID, 0);
                const option1 = await this.gov.proposalOptionState(proposalID, 1);
                const option2 = await this.gov.proposalOptionState(proposalID, 2);
                expect(option0.votes).to.be.bignumber.equal(ether('55.0'));
                expect(option1.votes).to.be.bignumber.equal(ether('55.0'));
                expect(option2.votes).to.be.bignumber.equal(ether('55.0'));
                expect(option0.agreement).to.be.bignumber.equal(ether('30'));
                expect(option1.agreement).to.be.bignumber.equal(ether('37'));
                expect(option2.agreement).to.be.bignumber.equal(ether('40'));
                expect(option0.agreementRatio).to.be.bignumber.equal(ratio('0.545454545454545454'));
                expect(option1.agreementRatio).to.be.bignumber.equal(ratio('0.672727272727272727'));
                expect(option2.agreementRatio).to.be.bignumber.equal(ratio('0.727272727272727272'));
                const votingInfo = await this.gov.calculateVotingTally(proposalID);
                expect(votingInfo.proposalResolved).to.equal(true);
                expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(2)); // option with a best opinion
                expect(votingInfo.votes).to.be.bignumber.equal(ether('55.0'));
                // clean up
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
            });

            it('checking voting state after first staker recounting', async () => {
                await this.govable.stake(firstVoterAcc, ether('10.0'), {from: firstVoterAcc});
                await this.gov.recountVote(firstVoterAcc, firstVoterAcc, proposalID, {from: otherAcc});
                // check
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID.sub(new BN(1)))).to.be.bignumber.equal(ether('0.0'));
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID)).to.be.bignumber.equal(ether('30.0'));
                const proposalStateInfo = await this.gov.proposalState(proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
                expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('70.0'));
                expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(0));
                const option0 = await this.gov.proposalOptionState(proposalID, 0);
                const option1 = await this.gov.proposalOptionState(proposalID, 1);
                const option2 = await this.gov.proposalOptionState(proposalID, 2);
                expect(option0.votes).to.be.bignumber.equal(ether('70.0'));
                expect(option1.votes).to.be.bignumber.equal(ether('70.0'));
                expect(option2.votes).to.be.bignumber.equal(ether('70.0'));
                expect(option0.agreement).to.be.bignumber.equal(ether('40'));
                expect(option1.agreement).to.be.bignumber.equal(ether('46'));
                expect(option2.agreement).to.be.bignumber.equal(ether('44'));
                expect(option0.agreementRatio).to.be.bignumber.equal(ratio('0.571428571428571428'));
                expect(option1.agreementRatio).to.be.bignumber.equal(ratio('0.657142857142857142'));
                expect(option2.agreementRatio).to.be.bignumber.equal(ratio('0.628571428571428571'));
                const votingInfo = await this.gov.calculateVotingTally(proposalID);
                expect(votingInfo.proposalResolved).to.equal(true);
                expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(1)); // option with a best opinion
                expect(votingInfo.votes).to.be.bignumber.equal(ether('70.0'));
                // clean up
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
            });

            it('checking voting state after cross-delegations between voters', async () => {
                await this.govable.stake(firstVoterAcc, ether('10.0'), {from: secondVoterAcc});
                await this.govable.stake(secondVoterAcc, ether('5.0'), {from: firstVoterAcc});
                await this.gov.vote(firstVoterAcc, proposalID, [new BN(0), new BN(1), new BN(2)], {from: secondVoterAcc});
                await expectRevert(this.gov.recountVote(firstVoterAcc, firstVoterAcc, proposalID, {from: otherAcc}), 'nothing changed');
                await this.gov.recountVote(secondVoterAcc, secondVoterAcc, proposalID, {from: otherAcc});
                // check
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID)).to.be.bignumber.equal(ether('40.0'));
                expect(await this.gov.overriddenWeight(secondVoterAcc, proposalID)).to.be.bignumber.equal(ether('0.0'));
                const proposalStateInfo = await this.gov.proposalState(proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
                expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('75.0'));
                expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(0));
                const option0 = await this.gov.proposalOptionState(proposalID, 0);
                const option1 = await this.gov.proposalOptionState(proposalID, 1);
                const option2 = await this.gov.proposalOptionState(proposalID, 2);
                expect(option0.votes).to.be.bignumber.equal(ether('75.0'));
                expect(option1.votes).to.be.bignumber.equal(ether('75.0'));
                expect(option2.votes).to.be.bignumber.equal(ether('75'));
                expect(option0.agreement).to.be.bignumber.equal(ether('35'));
                expect(option1.agreement).to.be.bignumber.equal(ether('48'));
                expect(option2.agreement).to.be.bignumber.equal(ether('55'));
                expect(option0.agreementRatio).to.be.bignumber.equal(ratio('0.466666666666666666'));
                expect(option1.agreementRatio).to.be.bignumber.equal(ratio('0.64'));
                expect(option2.agreementRatio).to.be.bignumber.equal(ratio('0.733333333333333333'));
                const votingInfo = await this.gov.calculateVotingTally(proposalID);
                expect(votingInfo.proposalResolved).to.equal(true);
                expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(2)); // option with a best opinion
                expect(votingInfo.votes).to.be.bignumber.equal(ether('75.0'));
                // clean up
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: secondVoterAcc});
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: firstVoterAcc});
                await this.gov.cancelVote(firstVoterAcc, proposalID, {from: delegatorAcc});
                await this.gov.cancelVote(secondVoterAcc, proposalID, {from: secondVoterAcc});
            });

            it('cancel votes via recounting', async () => {
                this.govable.unstake(firstVoterAcc, ether('10.0'), {from: firstVoterAcc});
                this.govable.unstake(secondVoterAcc, ether('20.0'), {from: secondVoterAcc});
                this.govable.unstake(firstVoterAcc, ether('30.0'), {from: delegatorAcc});
                await this.gov.recountVote(firstVoterAcc, firstVoterAcc, proposalID, {from: otherAcc});
                await this.gov.recountVote(secondVoterAcc, secondVoterAcc, proposalID, {from: otherAcc});
                await this.gov.recountVote(delegatorAcc, firstVoterAcc, proposalID, {from: otherAcc});
            });

            it('cancel votes via recounting gradually', async () => {
                this.govable.unstake(firstVoterAcc, ether('10.0'), {from: firstVoterAcc});
                await this.gov.recountVote(firstVoterAcc, firstVoterAcc, proposalID, {from: otherAcc});
                this.govable.unstake(secondVoterAcc, ether('20.0'), {from: secondVoterAcc});
                await this.gov.recountVote(secondVoterAcc, secondVoterAcc, proposalID, {from: otherAcc});
                this.govable.unstake(firstVoterAcc, ether('30.0'), {from: delegatorAcc});
                await this.gov.recountVote(delegatorAcc, firstVoterAcc, proposalID, {from: otherAcc});
            });

            it('cancel votes via recounting in reversed order', async () => {
                this.govable.unstake(firstVoterAcc, ether('10.0'), {from: firstVoterAcc});
                this.govable.unstake(secondVoterAcc, ether('20.0'), {from: secondVoterAcc});
                this.govable.unstake(firstVoterAcc, ether('30.0'), {from: delegatorAcc});
                await this.gov.recountVote(delegatorAcc, firstVoterAcc, proposalID, {from: otherAcc});
                await this.gov.recountVote(secondVoterAcc, secondVoterAcc, proposalID, {from: otherAcc});
                // firstVoterAcc's self-vote is erased after delegator's recounting
                await expectRevert(this.gov.recountVote(firstVoterAcc, firstVoterAcc, proposalID, {from: otherAcc}), "doesn't exist");
            });

            it('cancel votes via recounting gradually in reversed order', async () => {
                this.govable.unstake(firstVoterAcc, ether('30.0'), {from: delegatorAcc});
                await this.gov.recountVote(delegatorAcc, firstVoterAcc, proposalID, {from: otherAcc});
                this.govable.unstake(secondVoterAcc, ether('20.0'), {from: secondVoterAcc});
                await this.gov.recountVote(secondVoterAcc, secondVoterAcc, proposalID, {from: otherAcc});
                this.govable.unstake(firstVoterAcc, ether('10.0'), {from: firstVoterAcc});
                await this.gov.recountVote(firstVoterAcc, firstVoterAcc, proposalID, {from: otherAcc});
            });

            afterEach('checking state is empty', async () => {
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID.sub(new BN(1)))).to.be.bignumber.equal(ether('0.0'));
                expect(await this.gov.overriddenWeight(firstVoterAcc, proposalID)).to.be.bignumber.equal(ether('0.0'));
                const proposalStateInfo = await this.gov.proposalState(proposalID);
                expect(proposalStateInfo.winnerOptionID).to.be.bignumber.equal(new BN(0));
                expect(proposalStateInfo.votes).to.be.bignumber.equal(ether('0.0'));
                expect(proposalStateInfo.status).to.be.bignumber.equal(new BN(0));
                const voteInfo1 = await this.gov.getVote(firstVoterAcc, firstVoterAcc, proposalID);
                expect(voteInfo1.weight).to.be.bignumber.equal(ether('0.0'));
                expect(voteInfo1.choices.length).to.equal(0);
                const voteInfo2 = await this.gov.getVote(secondVoterAcc, secondVoterAcc, proposalID);
                expect(voteInfo2.weight).to.be.bignumber.equal(ether('0.0'));
                expect(voteInfo2.choices.length).to.equal(0);
                const voteInfo3 = await this.gov.getVote(delegatorAcc, firstVoterAcc, proposalID);
                expect(voteInfo3.weight).to.be.bignumber.equal(ether('0.0'));
                expect(voteInfo3.choices.length).to.equal(0);
                const voteInfo4 = await this.gov.getVote(firstVoterAcc, delegatorAcc, proposalID);
                expect(voteInfo4.weight).to.be.bignumber.equal(ether('0.0'));
                expect(voteInfo4.choices.length).to.equal(0);
                const option0 = await this.gov.proposalOptionState(proposalID, 0);
                const option2 = await this.gov.proposalOptionState(proposalID, 2);
                expect(option0.votes).to.be.bignumber.equal(ether('0.0'));
                expect(option2.votes).to.be.bignumber.equal(ether('0.0'));
                expect(option0.agreement).to.be.bignumber.equal(ether('0.0'));
                expect(option2.agreement).to.be.bignumber.equal(ether('0.0'));
                expect(option0.agreementRatio).to.be.bignumber.equal(ratio('0.0'));
                expect(option2.agreementRatio).to.be.bignumber.equal(ratio('0.0'));
                const votingInfo = await this.gov.calculateVotingTally(proposalID);
                expect(votingInfo.proposalResolved).to.equal(false);
                expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(optionsNum));
                expect(votingInfo.votes).to.be.bignumber.equal(ether('0.0'));
                await expectRevert(this.gov.handleTasks(0, 1), 'no tasks handled');
                await expectRevert(this.gov.tasksCleanup(1), 'no tasks erased');
                await expectRevert(this.gov.recountVote(firstVoterAcc, firstVoterAcc, proposalID, {from: otherAcc}), "doesn't exist");
                await expectRevert(this.gov.recountVote(delegatorAcc, firstVoterAcc, proposalID, {from: otherAcc}), "doesn't exist");
                await expectRevert(this.gov.recountVote(secondVoterAcc, secondVoterAcc, proposalID, {from: otherAcc}), "doesn't exist");
            });
        }
    }

    describe('checking votes for 1 delegation and 2 self-voters', votersAndDelegatorsTests(true));
    describe('checking votes for 2 self-voters and 1 delegation', votersAndDelegatorsTests(false));

    it('checking voting with custom parameters', async () => {
        await expectRevert(this.verifier.addTemplate(99, 'custom', emptyAddr, NonExecutableType, ratio('1.1'), ratio('0.6'), scales, 120, 1200, 0, 60), 'minVotes > 1.0');
        await expectRevert(this.verifier.addTemplate(99, 'custom', emptyAddr, NonExecutableType, ratio('0.4'), ratio('1.1'), scales, 120, 1200, 0, 60), 'minAgreement > 1.0');
        await expectRevert(this.verifier.addTemplate(99, 'custom', emptyAddr, NonExecutableType, ratio('0.4'), ratio('0.6'), [], 120, 1200, 0, 60), 'empty opinions');
        await expectRevert(this.verifier.addTemplate(99, 'custom', emptyAddr, NonExecutableType, ratio('0.4'), ratio('0.6'), [1, 2, 3, 0], 120, 1200, 0, 60), 'wrong order of opinions');
        await expectRevert(this.verifier.addTemplate(99, 'custom', emptyAddr, NonExecutableType, ratio('0.4'), ratio('0.6'), [0, 0, 0, 0], 120, 1200, 0, 60), 'all opinions are zero');
        await expectRevert(this.verifier.addTemplate(99, 'custom', emptyAddr, NonExecutableType, ratio('0.4'), ratio('0.6'), [0], 120, 1200, 0, 60), 'all opinions are zero');
        const optionsNum = 1;
        const proposalInfo = await createProposal(NonExecutableType, optionsNum, ratio('0.01'), ratio('1.0'), 10000, 100000, 1000000, [1000000000000]);
        const proposalID = proposalInfo.proposalID;
        // make new vote
        time.increase(10000 + 10);
        await this.govable.stake(defaultAcc, ether('10.0'));
        await expectRevert(this.gov.vote(defaultAcc, proposalID, [new BN(1)]), 'wrong opinion ID'); // only 1 opinion is defined
        await this.gov.vote(defaultAcc, proposalID, [new BN(0)]);

        // check voting
        const votingInfo = await this.gov.calculateVotingTally(proposalID);
        expect(votingInfo.proposalResolved).to.equal(true);
        expect(votingInfo.winnerID).to.be.bignumber.equal(new BN(0)); // option with a best opinion
        expect(votingInfo.votes).to.be.bignumber.equal(ether('10.0'));
        const option0 = await this.gov.proposalOptionState(proposalID, 0);
        expect(option0.votes).to.be.bignumber.equal(ether('10.0'));
        expect(option0.agreement).to.be.bignumber.equal(ether('10'));
        expect(option0.agreementRatio).to.be.bignumber.equal(ratio('1.0'));
    });

    it('checking OwnableVerifier', async () => {
        const ownableVerifier = await OwnableVerifier.new(this.gov.address, {from: otherAcc});
        await this.verifier.addTemplate(1, 'plaintext', ownableVerifier.address, NonExecutableType, ratio('0.4'), ratio('0.6'), [0, 1, 2, 3, 4], 120, 1200, 0, 60);
        const option = web3.utils.fromAscii('option');
        const proposal = await PlainTextProposal.new('plaintext', 'plaintext-descr', [option], ratio('0.5'), ratio('0.8'), 30, 121, 1199, this.verifier.address);

        await expectRevert(this.gov.createProposal(proposal.address, {value: this.proposalFee, from: defaultAcc}), 'proposal contract failed verification');
        await expectRevert(this.gov.createProposal(proposal.address, {value: this.proposalFee, from: otherAcc}), 'proposal contract failed verification');
        await expectRevert(ownableVerifier.createProposal(proposal.address, {value: this.proposalFee, from: defaultAcc}), 'Ownable: caller is not the owner');
        await ownableVerifier.createProposal(proposal.address, {value: this.proposalFee, from: otherAcc});
        await expectRevert(this.gov.createProposal(proposal.address, {value: this.proposalFee, from: defaultAcc}), 'proposal contract failed verification');
        await expectRevert(this.gov.createProposal(proposal.address, {value: this.proposalFee, from: otherAcc}), 'proposal contract failed verification');
        await expectRevert(ownableVerifier.createProposal(proposal.address, {value: this.proposalFee, from: defaultAcc}), 'Ownable: caller is not the owner');

        await ownableVerifier.transferOwnership(defaultAcc, {from: otherAcc});

        await expectRevert(this.gov.createProposal(proposal.address, {value: this.proposalFee, from: otherAcc}), 'proposal contract failed verification');
        await expectRevert(this.gov.createProposal(proposal.address, {value: this.proposalFee, from: defaultAcc}), 'proposal contract failed verification');
        await expectRevert(ownableVerifier.createProposal(proposal.address, {value: this.proposalFee, from: otherAcc}), 'Ownable: caller is not the owner');
        await ownableVerifier.createProposal(proposal.address, {value: this.proposalFee, from: defaultAcc});
    });

    it('checking SlashingRefundProposal naming scheme', async () => {
        await this.verifier.addTemplate(5003, 'SlashingRefundProposals', emptyAddr, DelegatecallType, ratio('0.5'), ratio('0.8'), [0, 1, 2, 3, 4], 121, 1199, 30, 30);
        const proposal0 = await SlashingRefundProposal.new(0, 'description', ratio('0.5'), ratio('0.8'), 30, 121, 1199, emptyAddr, this.verifier.address);
        const proposal1 = await SlashingRefundProposal.new(1, 'description', ratio('0.5'), ratio('0.8'), 30, 121, 1199, emptyAddr, this.verifier.address);
        const proposal5 = await SlashingRefundProposal.new(5, 'description', ratio('0.5'), ratio('0.8'), 30, 121, 1199, emptyAddr, this.verifier.address);
        const proposal9 = await SlashingRefundProposal.new(9, 'description', ratio('0.5'), ratio('0.8'), 30, 121, 1199, emptyAddr, this.verifier.address);
        const proposal10 = await SlashingRefundProposal.new(10, 'description', ratio('0.5'), ratio('0.8'), 30, 121, 1199, emptyAddr, this.verifier.address);
        const proposal21 = await SlashingRefundProposal.new(21, 'description', ratio('0.5'), ratio('0.8'), 30, 121, 1199, emptyAddr, this.verifier.address);
        const proposal99 = await SlashingRefundProposal.new(99, 'description', ratio('0.5'), ratio('0.8'), 30, 121, 1199, emptyAddr, this.verifier.address);
        const proposal100 = await SlashingRefundProposal.new(100, 'description', ratio('0.5'), ratio('0.8'), 30, 121, 1199, emptyAddr, this.verifier.address);
        const proposal999 = await SlashingRefundProposal.new(999, 'description', ratio('0.5'), ratio('0.8'), 30, 121, 1199, emptyAddr, this.verifier.address);

        expect(await proposal0.description()).to.equal('description');

        expect(await proposal0.name()).to.equal('Refund for Slashed Validator #0');
        expect(await proposal1.name()).to.equal('Refund for Slashed Validator #1');
        expect(await proposal5.name()).to.equal('Refund for Slashed Validator #5');
        expect(await proposal9.name()).to.equal('Refund for Slashed Validator #9');
        expect(await proposal10.name()).to.equal('Refund for Slashed Validator #10');
        expect(await proposal21.name()).to.equal('Refund for Slashed Validator #21');
        expect(await proposal99.name()).to.equal('Refund for Slashed Validator #99');
        expect(await proposal100.name()).to.equal('Refund for Slashed Validator #100');
        expect(await proposal999.name()).to.equal('Refund for Slashed Validator #999');
    });
});
