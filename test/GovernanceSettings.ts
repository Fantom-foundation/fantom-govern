import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import {ethers} from "hardhat";
import {expect} from "chai";
import {hours} from "@nomicfoundation/hardhat-network-helpers/dist/src/helpers/time/duration";



describe("GovernanceSettings", function () {
    const fixture = async function () {
        const gov = await ethers.deployContract("Governance");
        const [defaultAcc, otherAcc] = await ethers.getSigners();
        return {
            gov,
            defaultAcc,
            otherAcc,
        }
    }
    beforeEach(async function () {
        Object.assign(this, await loadFixture(fixture));
    });
    it("proposalFee is changeable by owner", async function () {
        const newProposalFee = 1000;
        await expect(this.gov.connect(this.otherAcc).setProposalFee(newProposalFee)).to.be.revertedWithCustomError(
            this.gov,
            'OwnableUnauthorizedAccount',
        );
        // Make sure default value is different
        expect(await this.gov.proposalFee()).not.to.be.equal(BigInt(newProposalFee*1e18));
        await this.gov.connect(this.defaultAcc).setProposalFee(newProposalFee);
        expect(await this.gov.proposalFee()).to.be.equal(BigInt(newProposalFee*1e18));
    })
    it("proposalBurntFee is changeable by owner", async function () {
        const newProposalBurntFee = 1;
        await expect(this.gov.connect(this.otherAcc).setProposalBurntFee(newProposalBurntFee)).to.be.revertedWithCustomError(
            this.gov,
            'OwnableUnauthorizedAccount',
        );
        // Make sure default value is different
        expect(await this.gov.proposalBurntFee()).not.to.be.equal(BigInt(newProposalBurntFee*1e18));
        await this.gov.connect(this.defaultAcc).setProposalBurntFee(newProposalBurntFee);
        expect(await this.gov.proposalBurntFee()).to.be.equal(BigInt(newProposalBurntFee*1e18));
    })
    it("taskHandlingReward is changeable by owner", async function () {
        const newTaskHandlingReward = 1;
        await expect(this.gov.connect(this.otherAcc).setTaskHandlingReward(newTaskHandlingReward)).to.be.revertedWithCustomError(
            this.gov,
            'OwnableUnauthorizedAccount',
        );
        // Make sure default value is different
        expect(await this.gov.taskHandlingReward()).not.to.be.equal(BigInt(newTaskHandlingReward*1e18));
        await this.gov.connect(this.defaultAcc).setTaskHandlingReward(newTaskHandlingReward);
        expect(await this.gov.taskHandlingReward()).to.be.equal(BigInt(newTaskHandlingReward*1e18));
    })
    it("taskErasingReward is changeable by owner", async function () {
        const newTaskErasingReward = 1;
        await expect(this.gov.connect(this.otherAcc).setTaskErasingReward(newTaskErasingReward)).to.be.revertedWithCustomError(
            this.gov,
            'OwnableUnauthorizedAccount',
        );
        // Make sure default value is different
        expect(await this.gov.taskErasingReward()).not.to.be.equal(BigInt(newTaskErasingReward*1e18));
        await this.gov.connect(this.defaultAcc).setTaskErasingReward(newTaskErasingReward);
        expect(await this.gov.taskErasingReward()).to.be.equal(BigInt(newTaskErasingReward*1e18));
    })
    it("maxOptions is changeable by owner", async function () {
        const newMaxOptions = 1n;
        await expect(this.gov.connect(this.otherAcc).setMaxOptions(newMaxOptions)).to.be.revertedWithCustomError(
            this.gov,
            'OwnableUnauthorizedAccount',
        );
        // Make sure default value is different
        expect(await this.gov.maxOptions()).not.to.be.equal(newMaxOptions);
        await this.gov.connect(this.defaultAcc).setMaxOptions(newMaxOptions);
        expect(await this.gov.maxOptions()).to.be.equal(newMaxOptions);
    })
    it("maxExecutionPeriod is changeable by owner", async function () {
        const newMaxExecutionPeriod = 1;
        await expect(this.gov.connect(this.otherAcc).setMaxExecutionPeriod(newMaxExecutionPeriod)).to.be.revertedWithCustomError(
            this.gov,
            'OwnableUnauthorizedAccount',
        );
        // Make sure default value is different
        expect(await this.gov.maxExecutionPeriod()).not.to.be.equal(hours(newMaxExecutionPeriod));
        await this.gov.connect(this.defaultAcc).setMaxExecutionPeriod(newMaxExecutionPeriod);
        expect(await this.gov.maxExecutionPeriod()).to.be.equal(hours(newMaxExecutionPeriod));
    })

})

describe("GovernanceSettings - proposalFeeTooLow", function () {
    const fixture = async function () {
        const gov = await ethers.deployContract("Governance");
        const [defaultAcc, otherAcc] = await ethers.getSigners();
        // Set rewards and burntFee to 1
        await gov.connect(defaultAcc).setProposalBurntFee(1);
        await gov.connect(defaultAcc).setTaskHandlingReward(1);
        await gov.connect(defaultAcc).setTaskErasingReward(1);
        // Set proposalFee to sum of the values above
        await gov.connect(defaultAcc).setProposalFee(3);
        return {
            gov,
            defaultAcc,
            otherAcc,
        }
    }
    beforeEach(async function () {
        Object.assign(this, await loadFixture(fixture));
    });
    it("setProposalFee should revert when lower than sum of rewards and burntFee", async function () {
        const newProposalFee = 2;
        await expect(this.gov.connect(this.defaultAcc).setProposalFee(newProposalFee)).to.be.revertedWithCustomError(
            this.gov,
            'ProposalFeeTooLow',
        ).withArgs(BigInt(3*1e18));
    })
    it("setProposalBurntFee should revert when proposalFee is too low", async function () {
        const newProposalBurntFee = 2;
        await expect(this.gov.connect(this.defaultAcc).setProposalBurntFee(newProposalBurntFee)).to.be.revertedWithCustomError(
            this.gov,
            'ProposalFeeTooLow',
        ).withArgs(BigInt(4*1e18));
    })
    it("taskHandlingReward is changeable by owner", async function () {
        const setTaskHandlingReward = 2;
        await expect(this.gov.connect(this.defaultAcc).setTaskHandlingReward(setTaskHandlingReward)).to.be.revertedWithCustomError(
            this.gov,
            'ProposalFeeTooLow',
        ).withArgs(BigInt(4*1e18));
    })
    it("taskErasingReward is changeable by owner", async function () {
        const setTaskErasingReward = 2;
        await expect(this.gov.connect(this.defaultAcc).setTaskErasingReward(setTaskErasingReward)).to.be.revertedWithCustomError(
            this.gov,
            'ProposalFeeTooLow',
        ).withArgs(BigInt(4*1e18));
    })
})
