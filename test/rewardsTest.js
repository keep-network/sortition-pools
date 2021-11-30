const chai = require("chai")
const expect = chai.expect
const { ethers, helpers } = require("hardhat")

describe("Rewards", () => {
  let alice
  let bob
  let carol

  let rewards

  beforeEach(async () => {
    alice = (await ethers.getSigner(0)).address
    bob = (await ethers.getSigner(1)).address
    carol = (await ethers.getSigner(2)).address

    const RewardsStub = await ethers.getContractFactory("RewardsStub")
    rewards = await RewardsStub.deploy()
    await rewards.deployed()
  })

  describe("sortition pool rewards", async () => {
    it("pays rewards proportionally", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      const poolWeight = await rewards.getPoolWeight()

      expect(poolWeight).to.equal(100)

      await rewards.payReward(1000)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)

      expect(aliceRewards).to.be.equal(100)
      expect(bobRewards).to.be.equal(900)
    })

    it("only pays to present members", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      await rewards.updateOperatorWeight(bob, 0)

      await rewards.payReward(1000)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)

      expect(aliceRewards).to.equal(1000)
      expect(bobRewards).to.equal(0)
    })

    it("handles dust", async () => {
      await rewards.addOperator(alice, 10)

      await rewards.payReward(123)

      const acc1 = await rewards.getGlobalAccumulator()
      expect(acc1).to.equal(12)

      const dust1 = await rewards.getRoundingDust()
      expect(dust1).to.equal(3)

      await rewards.addOperator(bob, 20)

      await rewards.payReward(987)

      const acc2 = await rewards.getGlobalAccumulator()
      expect(acc2).to.equal(45)

      const dust2 = await rewards.getRoundingDust()
      expect(dust2).to.equal(0)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)

      expect(aliceRewards).to.equal(450)

      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)

      expect(bobRewards).to.equal(660)
    })

    it("handles sequences", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      // alice: 100; bob: 900
      await rewards.payReward(1000)

      const globalAcc1 = await rewards.getGlobalAccumulator()
      expect(globalAcc1).to.equal(10)

      await rewards.updateOperatorWeight(bob, 0)

      const bobRew1 = await rewards.getAccruedRewards(bob)
      expect(bobRew1).to.equal(900)

      const bobAcc1 = await rewards.getAccumulator(bob)
      expect(bobAcc1).to.equal(10)

      const aliceAcc1 = await rewards.getAccumulator(alice)
      expect(aliceAcc1).to.equal(0)

      // alice: 1000; bob: 0
      // alice total: 1100; bob total: 900
      await rewards.payReward(1000)

      const globalAcc2 = await rewards.getGlobalAccumulator()
      expect(globalAcc2).to.equal(110)

      await rewards.updateOperatorWeight(bob, 40)

      const bobRew2 = await rewards.getAccruedRewards(bob)
      expect(bobRew2).to.equal(900)

      const bobAcc2 = await rewards.getAccumulator(bob)
      expect(bobAcc2).to.equal(110)

      const aliceAcc2 = await rewards.getAccumulator(alice)
      expect(aliceAcc2).to.equal(0)

      // alice: 200; bob: 800
      // alice total: 1300; bob total: 1700
      await rewards.payReward(1000)

      const globalAcc3 = await rewards.getGlobalAccumulator()
      expect(globalAcc3).to.equal(130)

      const bobRew3 = await rewards.getAccruedRewards(bob)
      expect(bobRew3).to.equal(900)

      const bobAcc3 = await rewards.getAccumulator(bob)
      expect(bobAcc3).to.equal(110)

      const aliceAcc3 = await rewards.getAccumulator(alice)
      expect(aliceAcc3).to.equal(0)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)

      expect(aliceRewards).to.equal(1300)
      expect(bobRewards).to.equal(1700)
    })

    it("permits making operators ineligible", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      // Reward to both
      // Alice: 10; Bob: 90
      await rewards.payReward(100)

      await rewards.makeIneligible(bob, 10)

      const iWeight = await rewards.getIneligibleWeight()
      expect(iWeight).to.equal(90)

      // Reward only to Alice
      // Alice: 110; Bob: 90
      await rewards.payReward(100)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)

      expect(aliceRewards).to.equal(110)
      expect(bobRewards).to.equal(90)
    })

    it("permits making multiple operators ineligible", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 10)
      await rewards.addOperator(carol, 10)

      // Reward to all
      // Alice: 10; Bob: 10; Carol: 10
      await rewards.payReward(30)

      await rewards.massMakeIneligible([bob, carol], 10)

      const iWeight = await rewards.getIneligibleWeight()
      expect(iWeight).to.equal(20)

      // Reward only to Alice
      // Alice: 40; Bob: 10; Carol: 10
      await rewards.payReward(30)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)
      await rewards.withdrawRewards(carol)
      const carolRewards = await rewards.getWithdrawnRewards(carol)

      expect(aliceRewards).to.equal(40)
      expect(bobRewards).to.equal(10)
      expect(carolRewards).to.equal(10)
    })

    it("permits restoring operator eligibility", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      // Reward to both
      // Alice: 10; Bob: 90
      await rewards.payReward(100)

      await rewards.makeIneligible(bob, 10)

      // Reward only to Alice
      // Alice: 110; Bob: 90
      await rewards.payReward(100)

      await helpers.time.increaseTime(11)

      await rewards.makeEligible(bob)

      const iWeight = await rewards.getIneligibleWeight()
      expect(iWeight).to.equal(0)

      // Reward to both
      // Alice: 120; Bob: 180
      await rewards.payReward(100)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)

      expect(aliceRewards).to.equal(120)
      expect(bobRewards).to.equal(180)
    })

    it("won't restore eligibility prematurely", async () => {
      await rewards.addOperator(alice, 10)

      await rewards.makeIneligible(alice, 10)

      await expect(rewards.makeEligible(alice)).to.be.revertedWith(
        "Operator still ineligible",
      )
    })

    it("permits changing ineligible operator weight", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      await rewards.makeIneligible(bob, 10)

      await rewards.updateOperatorWeight(bob, 40)

      const iWeight = await rewards.getIneligibleWeight()
      expect(iWeight).to.equal(40)

      // Reward only to Alice
      // Alice: 100; Bob: 0
      await rewards.payReward(100)

      await helpers.time.increaseTime(11)

      await rewards.makeEligible(bob)

      // Reward to both
      // Alice: 120; Bob: 80
      await rewards.payReward(100)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)

      expect(aliceRewards).to.equal(120)
      expect(bobRewards).to.equal(80)
    })

    it("handles lengthening ineligibility", async () => {
      await rewards.addOperator(alice, 10)

      await rewards.makeIneligible(alice, 10)
      await rewards.makeIneligible(alice, 100)

      await helpers.time.increaseTime(11)

      await expect(rewards.makeEligible(alice)).to.be.revertedWith(
        "Operator still ineligible",
      )
    })

    it("won't shorten ineligibility", async () => {
      await rewards.addOperator(alice, 10)

      await rewards.makeIneligible(alice, 100)
      await rewards.makeIneligible(alice, 10)

      await helpers.time.increaseTime(11)

      await expect(rewards.makeEligible(alice)).to.be.revertedWith(
        "Operator still ineligible",
      )
    })
  })
})
