import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import {ethers} from "hardhat";
import {expect} from "chai";


const sfcToGovernableFixture = async () => {
    const sfc = await ethers.deployContract("UnitTestSFC");
    const govable = await ethers.deployContract("SFCToGovernable", [await sfc.getAddress()]);
    const [validator1, validator2, acc1, acc2] = await ethers.getSigners();
    await sfc.addValidator(1, 0, validator1);
    await sfc.addValidator(2, 0, validator2);
    return {sfc, govable, validator1, validator2, acc1, acc2}
}

describe("SFCToGovernable test", function () {
    beforeEach(async function (){
        Object.assign(this, await loadFixture(sfcToGovernableFixture));
    });
    it("getTotalWeight() returns sum of all stakes", async function () {
        // add stake
        await this.sfc.connect(this.acc1).stake(this.validator1, 200);
        await this.sfc.connect(this.acc2).stake(this.validator2, 100);
        // check stake
        expect(await this.govable.getTotalWeight()).to.equal(300);
    })
    it("getReceivedWeight() should return 0 stake if validator.status != 0", async function () {
        // add validator with status != 0
        await this.sfc.addValidator(3, 1, this.acc1);
        // add stake
        await this.sfc.stake(this.acc1, ethers.parseEther("100"));
        // check stake
        expect(await this.govable.getReceivedWeight(this.acc1)).to.equal(0);
    })
    it("getReceivedWeight() should return 0 stake if validator does not exist", async function () {
        // check stake
        expect(await this.govable.getReceivedWeight(this.acc1)).to.equal(0);
    })
    it("getWeight() should return 0 stake if validator does not exist", async function () {
        // check stake
        expect(await this.govable.getWeight(this.acc1, this.acc2)).to.equal(0);
    })
    it("getWeight() should return 0 stake if validator.status != 0", async function () {
        // add validator with status != 0
        await this.sfc.addValidator(3, 1, this.acc2);
        expect(await this.govable.getWeight(this.acc1, this.acc2)).to.equal(0);
    })
    it("getWeight() should return the stake", async function () {
        // stake two accounts
        await this.sfc.connect(this.acc1).stake(this.validator1, 200);
        await this.sfc.connect(this.acc2).stake(this.validator2, 100);
        expect(await this.govable.getWeight(this.acc1, this.validator1)).to.equal(200);
        expect(await this.govable.getWeight(this.acc2, this.validator2)).to.equal(100);
    })
})