const {
    BN,
    ether,
    expectRevert,
    time,
    balance,
} = require('openzeppelin-test-helpers');
const {expect} = require('chai');

const Web3 = require('web3');
const testHelper = require('./testHelper');
const truffleAssert = require('truffle-assertions');

const showLogs = true;
const Zero = new BN(0);

var web3 = new Web3();
web3.setProvider(Web3.givenProvider || 'ws://localhost:8545')//..Web3.givenProvider);

const Governance = artifacts.require('TestGovernance'); // UnitTestGovernance .sol
const UnitTestStakers = artifacts.require('UnitTestStakers');
const UnitTestProposal = artifacts.require('UnitTestProposal');
const ProposalFactory = artifacts.require('TestProposalFactory');
const UpgradeabilityProxy = artifacts.require('UpgradeabilityProxy');
const DummySoftwareContract = artifacts.require('DummySoftwareContract');
const DummySoftwareUpgradeProposal = artifacts.require('DummySoftwareUpgradeProposal');
const GovernanceProd = artifacts.require("Governance");
const stakerMetadata = "0x0001";

const minStartingDeposit = "150";
const minProposalDeposit = "1500";
const largeProposalDeposit = "15000";
const expectedMinimumVotesRequired = "";

const minute = 60;
const hour = minute * 60;
const day = hour * 24;
const week = day * 7;
const defaultDepositingPeriod = 2 * week;

const statusDepositing = new BN("1"); // 0x01 (just active )
const statusVoting = new BN("5"); // 0x01 (active) |= 1 << 2
const statusFail = new BN("16");

contract('Governance test', async ([acc0, acc1, acc2, acc3, acc4, acc5, contractAddr]) => {
    beforeEach(async () => {
        if (!showLogs)
            console.log = function() {}

        this.firstEpoch = 0;
        this.stakers = await UnitTestStakers.new(this.firstEpoch);
        this.upgradeabilityProxy = await UpgradeabilityProxy.new();
        this.proposalFactory = await ProposalFactory.new(this.upgradeabilityProxy.address);
        this.governance = await Governance.new(this.stakers.address, this.proposalFactory.address);
        this.dummySoftwareContract = await DummySoftwareContract.new();
        const dummyAddr = this.dummySoftwareContract.address;
        this.dummySoftwareUpgradeProposal = await DummySoftwareUpgradeProposal.new(dummyAddr, dummyAddr);
        this.governanceProd = await GovernanceProd.new(this.stakers.address, this.proposalFactory.address);
        // this.proposal = await UnitTestProposal.new();
    });

    it('test create proposal', async () => {
        // await this.governance.handleDeadlines(0, 40);
        let ptpId = await createPTP(this.proposalFactory, this.governance, acc1);
        let {supId, proposalAddress} = await createSUP(this.proposalFactory, this.governance, this.dummySoftwareContract, acc1);
        
        await this.stakers._createStake({from: acc1, value: ether('2.0')});
        await resolveProp(this.governance, ptpId, acc1);
    })

    it('test create proposal alowance', async () => {
        let unregisteredContractAddress = this.dummySoftwareUpgradeProposal.address;
        await expectRevert(createProposal(this.governance, unregisteredContractAddress, acc1), "cannot vote for a given proposal");
        let lastProposalId = await this.governance.lastProposalId();
        expect(lastProposalId).to.be.bignumber.equal(Zero, "last proposal id is not zero");

        let ptpId = await createPTP(this.proposalFactory, this.governance, acc1);

        lastProposalId = await this.governance.lastProposalId();
        expect(lastProposalId).to.be.bignumber.equal(new BN(1), "last proposal id is not 1");
    })

    it('test params of a created proposal', async () => {
        let stakeVal = ether('2.0');
        let expectedOptions = ["yes", "no"];
        await this.stakers._createStake({from: acc1, value: stakeVal});
        let {supId, proposalAddress} = await createSUP(this.proposalFactory, this.governance, this.dummySoftwareContract, acc1);
        let proposalDescription = await this.governance.getProposalDescription(supId);
        let expectedRequiredVotes = await getExpectedRequiredVotes(stakeVal);

        let lrcOption1 = await this.governance.getProposalLrcOption(supId, 0);
        let lrcOption2 = await this.governance.getProposalLrcOption(supId, 1);
        let asciDesc1 = web3.utils.toAscii(lrcOption1.description).replace(/\0/g, ''); // transform bytes32 to ascii and replace null symbs
        let asciDesc2 = web3.utils.toAscii(lrcOption2.description).replace(/\0/g, '');

        expect(proposalDescription.proposalContract).to.eql(proposalAddress, "created proposal address is incorrect");
        expect(proposalDescription.deposit).to.be.bignumber.equal(new BN(minStartingDeposit), "proposal starting deposit is incorect");
        expect(proposalDescription.requiredVotes).to.be.bignumber.equal(expectedRequiredVotes, "proposal required votes are incorrect");
        expect(asciDesc1).to.eql(expectedOptions[0], "wrong options for asciDesc1");
        expect(asciDesc2).to.eql(expectedOptions[1], "wrong options for asciDesc2");

        await expectRevert(this.governance.getProposalLrcOption(supId, 2), "option description is empty, so probably LRC option is empty too");
    })

    it('test starting deposit', async () => {
        const sender = acc1;
        let stakeVal = ether('2.0');
        let expectedOptions = ["yes", "no"];
        await this.stakers._createStake({from: sender, value: stakeVal});

        // creating proposal contract
        let title = Web3.utils.fromAscii("some title");
        let description = Web3.utils.fromAscii("some description");
        let options = [Web3.utils.fromAscii("yes"), Web3.utils.fromAscii("no")];
        
        let tx = await this.proposalFactory.newPlainTextProposal(title, description, options);
        let proposalAddress = tx.logs[0].args.proposalAddress;
        
        // setting proposal
        await expectRevert(this.governance.createProposal(proposalAddress, "0", {from: sender, value: minStartingDeposit}), "required deposit for a proposal is too small");

        // not realy a nice line of code, but short. we assume that minProposalDeposit is string, not BN
        let enlargedProposalDeposit = new BN(minProposalDeposit + "0");
        tx = await this.governance.createProposal(proposalAddress, enlargedProposalDeposit, {from: sender, value: minStartingDeposit});
        let newProposalId = tx.logs[0].args.proposalId;
        let prop = await this.governance.getProposalDescription(newProposalId);
        expect(prop.requiredDeposit).to.be.bignumber.equal(enlargedProposalDeposit, "proposal starting deposit is incorrect");
        return newProposalId;
    })

    it('test depositing period', async () => {
        const sender = acc1;
        let stakeVal = ether('1.0');
        await this.stakers._createStake({from: sender, value: stakeVal});
        let proposalIds = await createPTPs(this.proposalFactory, this.governanceProd, sender, 3);
        console.log("proposalIds", proposalIds);
        let firstProposal = proposalIds[0];
        let secondProposal = proposalIds[1];
        let thirdProposal = proposalIds[1];

        let currentBlock = await web3.eth.getBlock("latest");
        let expectedDeadline = currentBlock.timestamp + defaultDepositingPeriod;

        for (const proposalId of proposalIds) {
            let prop = await this.governanceProd.getProposalDescription(proposalId);
            expect(prop.depositingEndTime).to.be.bignumber.equal(new BN(expectedDeadline), "depositingDeadLine is set with error");
            expect(prop.status).to.be.bignumber.equal(statusDepositing, "proposal status should be 'depositing'");
        }

        // we imitate 10 seconds of waiting here. this time is not enought for deadline to pass
        await testHelper.advanceTimeAndBlock(10, web3);
        // we expect that no deadlines will be handeled
        // await this.governanceProd.handleDeadlines(0, 40);
        // we get prop description again to ensure it has not been resolved and it's status remains "depositing"
        let prop = await this.governanceProd.getProposalDescription(firstProposal);
        expect(prop.depositingEndTime).to.be.bignumber.equal(new BN(expectedDeadline), "depositingDeadLine changed unexpectedly");
        expect(prop.status).to.be.bignumber.equal(statusDepositing, "proposal status changed from 'depositing' unexpectedly");

        // we fill second proposal's deposit
        await this.governanceProd.increaseProposalDeposit(secondProposal, {from: acc1, value: minProposalDeposit});
        await this.governanceProd.increaseProposalDeposit(thirdProposal, {from: acc1, value: largeProposalDeposit});

        // now we wait for a deadline to pass to ensure that proposal is not resolved due to a lack of deposit
        await testHelper.advanceTimeAndBlock(expectedDeadline, web3);
        await this.governanceProd.handleDeadlines(0, 40);

        prop = await this.governanceProd.getProposalDescription(firstProposal);
        expect(prop.status).to.be.bignumber.equal(statusFail, "proposal should fail");

        prop = await this.governanceProd.getProposalDescription(secondProposal);
        expect(prop.status).to.be.bignumber.equal(statusVoting, "secondProposal should be at it's voting period");
        prop = await this.governanceProd.getProposalDescription(thirdProposal);
        expect(prop.status).to.be.bignumber.equal(statusVoting, "thirdProposal should be at it's voting period");
    })

    // TODO: test is not finished. Complete after LRC testing!!!!
    it("test voting power calculated correctly", async () => {
        const sender = acc1;
        // check that stakers contract is in a correct state
        let totalVotes = await this.stakers.getTotalVotes(0);
        expect(totalVotes).to.be.bignumber.equal(new BN(0));

        // create stakers with different stake siezes
        let minStake = await this.stakers.minStake();
        let mediumStake = minStake.mul(new BN("2"));
        let largeStake = minStake.mul(new BN("3"));
        let stakersDesc = [ 
            { address: acc1, stake: minStake },
            { address: acc2, stake: mediumStake }, 
            { address: acc3, stake: mediumStake }, 
            { address: acc4, stake: mediumStake },
            { address: acc5, stake: largeStake }
        ];

        let expectedTotalVotes = stakersDesc.reduce((accumulator, staker) => { 
            let acc = accumulator;
            if (accumulator.stake) {
                acc = accumulator.stake;
            } 
            
            return acc.add(staker.stake);  
        });
        stakersDesc.forEach(async stakerDesk => {
            await this.stakers._createStake({from: stakerDesk.address, value: stakerDesk.stake});
        });

        totalVotes = await this.stakers.getTotalVotes(0);
        expect(totalVotes).to.be.bignumber.equal(expectedTotalVotes);

        // creating proposal to check voting
        let proposalId = await createPTP(this.proposalFactory, this.governanceProd, sender);
        await this.governanceProd.increaseProposalDeposit(proposalId, {from: sender, value: minProposalDeposit});
        await testHelper.advanceTimeAndBlock(defaultDepositingPeriod + 1, web3);
        await this.governanceProd.handleDeadlines(0, 40);

        let prop = await this.governanceProd.getProposalDescription(proposalId);
        expect(prop.status).to.be.bignumber.equal(statusVoting, "proposal status with a filled deposit should be 'voting'");
    })

    it ("test base lrc calculation", async () => {
        // we will reproduce lrc voting below
        // first - we reproduce an LRC example from documentation
        // return
        let minStake = await this.stakers.minStake();
        let mediumStake = minStake.mul(new BN("2"));
        let largeStake = minStake.mul(new BN("3"));
        let stakersDesc = [ 
            { address: acc1, stake: minStake,    choises: ["4", "1"] },
            { address: acc2, stake: mediumStake, choises: ["1", "0"] }, 
            { address: acc3, stake: mediumStake, choises: ["2", "0"] }, 
            { address: acc4, stake: mediumStake, choises: ["2", "0"] },
            { address: acc5, stake: largeStake,  choises: ["0", "4"] }
        ];
        
        let totalStake = await createStakersSet(this.stakers, stakersDesc);
        for (const stakerDesc of stakersDesc) {
            let accWp = await this.governanceProd.accountVotingPower(stakerDesc.address, 0);
            expect(accWp[0]).to.be.bignumber.equal(stakerDesc.stake);
        }

        let option = new testHelper.LrcOption();
        option.opinions[1].count = option.opinions[1].count.add(new BN(6));
        option.opinions[4].count = option.opinions[4].count.add(new BN(5));
        option.totalVotes = new BN(11);
        option.calculate();
        expect(option.arc).to.be.bignumber.below(new BN(5640), "incorrect lrc calculation within test (below = false)");
        expect(option.arc).to.be.bignumber.above(new BN(5630), "incorrect lrc calculation within test (above = false)");

        // let's rescale our stake by 10000000000000000.
        // so for now our totalStake is 1 + 2 + 2 + 2 + 3 = 10
        // we expect that maxPossibleResistance would be 10 * 5 = 50
        // and that resistance (we make it just by voting for a position) would be 15 and 16 
        // so expected arc is (scale * resistance) / maxPossibleResistance = (1000 * N) / 50 where N is 15 or 16
        // the logic below cheks it
        let proposalId = await getPtpWithVoting(this.proposalFactory, this.governanceProd, acc0);
        let op1 = await this.governanceProd.getProposalLrcOption(proposalId, 0);
        let op2 = await this.governanceProd.getProposalLrcOption(proposalId, 1);

        let options = [ new testHelper.LrcOption(), new testHelper.LrcOption()];
        for (const stakerDesc of stakersDesc) {
            await this.governanceProd.vote(proposalId, stakerDesc.choises, {from: stakerDesc.address});
            for (let i = 0; i < stakerDesc.choises.length; i++) {
                let choise = stakerDesc.choises[i];
                let c = parseInt(choise);   
                options[i].opinions[c].count = options[i].opinions[c].count.add(stakerDesc.stake);
                options[i].totalVotes = options[i].totalVotes.add(stakerDesc.stake);
            }
        }

        let reducedWp = await this.governanceProd.reducedVotersPower(acc1, 1);
        op1 = await this.governanceProd.getProposalLrcOption(proposalId, 0);
        op2 = await this.governanceProd.getProposalLrcOption(proposalId, 1);
        options.forEach(option => {
            option.calculate();
            console.log("option.rawCount", option.rawCount.toString());
        });

        expect(op1.resistance).to.be.bignumber.equal(options[0].rawCount); // 15000000000000000000 expected
        expect(op2.resistance).to.be.bignumber.equal(options[1].rawCount); // 16000000000000000000 expected
        expect(op1.arc).to.be.bignumber.equal(options[0].arc);
        expect(op2.arc).to.be.bignumber.equal(options[1].arc);
        expect(op1.dw).to.be.bignumber.equal(options[0].dw);
        expect(op2.dw).to.be.bignumber.equal(options[1].dw);
    })

    it ("test proposal execution", async () => {
        return;
        let minStake = await this.stakers.minStake();
        let mediumStake = minStake.mul(new BN("2"));
        let largeStake = minStake.mul(new BN("3"));
        let stakersDesc = [ 
            { address: acc1, stake: minStake,    choises: ["4", "1"] },
            { address: acc2, stake: mediumStake, choises: ["1", "0"] }, 
            { address: acc3, stake: mediumStake, choises: ["2", "0"] }, 
            { address: acc4, stake: mediumStake, choises: ["2", "0"] },
            { address: acc5, stake: largeStake,  choises: ["0", "4"] }
        ];

        let totalStake = await createStakersSet(this.stakers, stakersDesc);
        for (const stakerDesc of stakersDesc) {
            let accWp = await this.governanceProd.accountVotingPower(stakersDesc.address, 0);
            console.log("accWp:", accWp)
            expect(accWp[0]).to.be.bignumber.equal(stakersDesc.stake);
        }
        
        let proposalId = await getPtpWithVoting(this.proposalFactory, this.governanceProd, acc0);
        console.log("getPtpWithVoting:", proposalId);
    })
})

// this funct automatically shifts time and HandlesDeadlines!!
async function getPtpWithVoting(proposalFactory, governance, sender) {
    let ptpId = await createPTP(proposalFactory, governance, sender);
    await governance.increaseProposalDeposit(ptpId, {from: sender, value: minProposalDeposit});
    await testHelper.advanceTimeAndBlock(defaultDepositingPeriod + 1, web3);
    await governance.handleDeadlines(0, 40);
    return ptpId;
}

async function getExpectedRequiredVotes(totalVotes) {
    let a1 = totalVotes.mul(new BN(67));
    let a2 = a1.div(new BN(100));
    // let consensus = oneThird.add(new BN(1));
    return a2;
}

// 
async function createStakersSet(stakersContract, stakersDesc) {
    for (const stakerDesc of stakersDesc) {
        await stakersContract._createStake({from: stakerDesc.address, value: stakerDesc.stake});
    }

    let totalStake = stakersDesc.reduce((accumulator, staker) => { 
        let acc = accumulator;
        if (accumulator.stake) {
            acc = accumulator.stake;
        } 
        
        return acc.add(staker.stake);  
    });

    return totalStake;
}

// нужно - получить все дедлайны Вообще
async function resolveProp(governance, id, acc1) {
    await governance.increaseProposalDeposit(id, {from: acc1, value: minProposalDeposit});

    console.log("increased deposit");
    // await new Promise(r => setTimeout(r, 5000));

    await testHelper.advanceTimeAndBlock(6, web3);

    let deadlinesNum = await governance.getDeadlinesCount();
    console.log("deadlinesNum", deadlinesNum.toString());


    let fDeadline = await governance.deadlines(0);
    console.log("first Deadline", fDeadline.toString());

    await governance.handleDeadlines(0, 40);
    console.log("deadlines resolved");

    deadlinesNum = await governance.getDeadlinesCount();
    console.log("new deadlinesNum: ", deadlinesNum.toString());

    
    let block0 = await web3.eth.getBlock("latest");
    console.log("current timestamp (0)", block0.timestamp);

    const voteChoises = ["1", "0"];
    console.log("prepare to vote");
    let voteTx = await governance.vote(id, voteChoises, {from: acc1});
    console.log("vote made");
    console.log("voteTx: ", voteTx);
    let voter = await governance.voters(acc1, id);
    let propOpts = await governance.getProposalOptions(id);
    let propTotalVotes = await governance.getProposalOptionsTotalVotes(id);
    console.log("voter", voter);
    console.log("propOpts", propOpts);
    console.log("propTotalVotes", propTotalVotes);
    // truffleAssert.eventEmitted(voteTx, 'UserVoted', (ev) => {
    //     console.log("truffleAssert.eventEmitted", ev);
    //     return;
    // });
    
    let propDesc = await governance.getProposalDescription(id);
    console.log("prop total votes:", propDesc.totalVotes.toString());

    
    let block1 = await web3.eth.getBlock("latest");
    console.log("current timestamp (1)", block1.timestamp);

    await testHelper.advanceTimeAndBlock(11, web3);
    let tx = await governance.handleDeadlines(0, 40);
    //console.log("tx handleDeadlines:", tx);
    // if (tx.logs[0].args) {
    //     let block2 = await web3.eth.getBlock("latest");
    //     let newFirstDeadline = await governance.deadlines(0);
    //     console.log("new first Deadline", newFirstDeadline.toString());
    //     console.log("current timestamp (2)", block2.timestamp);
    //     console.log("not handeled deadline", tx.logs[0].args.deadline.toString());
    // }

    deadlinesNum = await governance.getDeadlinesCount();
    console.log("final deadlinesNum: ", deadlinesNum.toString());

}

async function createSUP(proposalFactory, governance, dummySoftwareContract, acc1) {
    let title = Web3.utils.fromAscii("some title");
    let description = Web3.utils.fromAscii("some description");
    let options = [Web3.utils.fromAscii("yes"), Web3.utils.fromAscii("no")];
    
    let tx = await proposalFactory.newSoftwareUpgradeProposal(dummySoftwareContract.address);
    let proposalAddress = tx.logs[0].args.proposalAddress;
    console.log("proposalAddress", proposalAddress);

    tx = await governance.createProposal(proposalAddress, minProposalDeposit, {from: acc1, value: minStartingDeposit});
    let newProposalId = tx.logs[0].args.proposalId;
    console.log("newProposalId", newProposalId.toString());

    let prop = await governance.getProposalDescription(newProposalId);
    console.log(prop.status.toString());
    return { supId: newProposalId, proposalAddress: proposalAddress};
}

async function createPTPs(proposalFactory, governance, sender, num) {
    let proposalIds = [];
    while(num > 0) {
        num--;
        let propId = await createPTP(proposalFactory, governance, sender)
        proposalIds.push(propId);
    }

    return proposalIds;
}

async function createPTP(proposalFactory, governance, acc1) {
    let title = Web3.utils.fromAscii("some title");
    let description = Web3.utils.fromAscii("some description");
    let options = [Web3.utils.fromAscii("yes"), Web3.utils.fromAscii("no")];

    let tx = await proposalFactory.newPlainTextProposal(title, description, options);
    let proposalAddress = tx.logs[0].args.proposalAddress;
    console.log("proposalAddress", proposalAddress);

    // tx = await governance.createProposal(proposalAddress, minProposalDeposit, {from: acc1, value: minStartingDeposit});
    // let newProposalId = tx.logs[0].args.proposalId;
    // console.log("newProposalId", newProposalId.toString());

    // let prop = await governance.getProposalDescription(newProposalId);
    // console.log(prop);
    return await createProposal(governance, proposalAddress, acc1);
}

async function createProposal(governance, proposalAddress, sender) {
    tx = await governance.createProposal(proposalAddress, minProposalDeposit, {from: sender, value: minStartingDeposit});
    let newProposalId = tx.logs[0].args.proposalId;
    console.log("newProposalId", newProposalId.toString());
    let prop = await governance.getProposalDescription(newProposalId);
    console.log(prop);
    return newProposalId;
}

async function Log() {

}