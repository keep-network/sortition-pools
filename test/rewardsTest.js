const chai = require("chai")
const expect = chai.expect
const { ethers, helpers } = require("hardhat")

describe("Rewards", () => {
  const alice = 1
  const bob = 2
  const carol = 3

  let rewards

  beforeEach(async () => {
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

      // Since alice makes up 10 / 100 = 10% of the pool weight, alice expects
      // 10% of the rewards. 10% of 1000 is 100.
      expect(aliceRewards).to.be.equal(100)
      // Since bob makes up 90 / 100 = 90% of the pool weight, bob expects 90%
      // of the rewards. 90% of 1000 is 900.
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

      // Since alice made up 10 / 10 = 100% of the pool weight (as bob's weight
      // was updated to 0 before rewards were paid), alice expects 100% of
      // the rewards. 100% of 1000 is 1000.
      expect(aliceRewards).to.equal(1000)
      // Since bob made up 0 / 10 = 0% of the pool weight (as bob's weight was
      // updated to 0 before rewards were paid), bob expects 0% of the
      // rewards. 0% of 1000 is 0.
      expect(bobRewards).to.equal(0)
    })

    it("handles dust", async () => {
      await rewards.addOperator(alice, 10)

      await rewards.payReward(123)

      // The way that reward state is tracked is through a global accumulator
      // that simulates what a hypothetical 1-weight operator would receive in
      // rewards for each payout, accompanied by roundingDust variable that
      // stores integer division remainders. For this example, the pool has 10
      // weight, and a reward of 123 was just granted, so a 1-weight operator
      // would receive 12 rewards with 3 left over (12 * 10 + 3 = 123). The
      // remainder is added to the next reward.
      const acc1 = await rewards.getGlobalAccumulator()
      expect(acc1).to.equal(12)

      const dust1 = await rewards.getRoundingDust()
      expect(dust1).to.equal(3)

      await rewards.addOperator(bob, 20)

      await rewards.payReward(987)

      // We previously had a remainder of 3, and just received 987 rewards for
      // a total of 990. The total pool weight is 30, so our 1-weight operator
      // receives 990 / 30 = 33 rewards with 0 left over. That 33 is added to
      // the previous 12 to get to 45.
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

      // Accrued rewards only change when an operator is updated.
      const aliceRew1 = await rewards.getAccruedRewards(alice)
      expect(aliceRew1).to.equal(0)

      // An operator's accumulator state only changes when an operator is
      // updated.
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

      const aliceRew2 = await rewards.getAccruedRewards(alice)
      expect(aliceRew2).to.equal(0)

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

      const aliceRew3 = await rewards.getAccruedRewards(alice)
      expect(aliceRew3).to.equal(0)

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

      // Reward only to Alice, Bob's share goes to ineligible pot
      // Alice: 20; Bob: 90; Ineligible: 90
      await rewards.payReward(100)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)
      await rewards.withdrawIneligible()
      const ineligibleRewards = await rewards.getIneligibleRewards()

      expect(aliceRewards).to.equal(20)
      expect(bobRewards).to.equal(90)
      expect(ineligibleRewards).to.equal(90)
    })

    it("permits making multiple operators ineligible", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 10)
      await rewards.addOperator(carol, 10)

      // Reward to all
      // Alice: 10; Bob: 10; Carol: 10
      await rewards.payReward(30)

      await rewards.massMakeIneligible([bob, carol], 10)

      // Reward only to Alice, Bob's and Carol's share goes to ineligible
      // Alice: 20; Bob: 10; Carol: 10; Ineligible: 20
      await rewards.payReward(30)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)
      await rewards.withdrawRewards(carol)
      const carolRewards = await rewards.getWithdrawnRewards(carol)
      await rewards.withdrawIneligible()
      const ineligibleRewards = await rewards.getIneligibleRewards()

      expect(aliceRewards).to.equal(20)
      expect(bobRewards).to.equal(10)
      expect(carolRewards).to.equal(10)
      expect(ineligibleRewards).to.equal(20)
    })

    it("permits restoring operator eligibility", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      // Reward to both
      // Alice: 10; Bob: 90
      await rewards.payReward(100)

      // Make Bob ineligible for 10 units of time
      await rewards.makeIneligible(bob, 10)

      // Reward only to Alice
      // Alice: 20; Bob: 90; Ineligible: 90
      await rewards.payReward(100)

      // Ineligibility is set for a duration. Bob was ineligible for 10 units,
      // so we move forward 11 units to allow us to make him eligible again.
      await helpers.time.increaseTime(11)

      await rewards.makeEligible(bob)

      // Reward to both
      // Alice: 30; Bob: 180; Ineligible: 90
      await rewards.payReward(100)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)
      await rewards.withdrawIneligible()
      const ineligibleRewards = await rewards.getIneligibleRewards()

      expect(aliceRewards).to.equal(30)
      expect(bobRewards).to.equal(180)
      expect(ineligibleRewards).to.equal(90)
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

      // Reward only to Alice
      // Alice: 20; Bob: 0; Ineligible: 80
      await rewards.payReward(100)

      await helpers.time.increaseTime(11)

      await rewards.makeEligible(bob)

      // Reward to both
      // Alice: 40; Bob: 80; Ineligible: 80
      await rewards.payReward(100)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards(bob)
      await rewards.withdrawIneligible()
      const ineligibleRewards = await rewards.getIneligibleRewards()

      expect(aliceRewards).to.equal(40)
      expect(bobRewards).to.equal(80)
      expect(ineligibleRewards).to.equal(80)
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

    it("returns correct amount of available rewards", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 10)
      await rewards.addOperator(carol, 10)

      // Reward to all
      // Alice: 10; Bob: 10; Carol: 10
      await rewards.payReward(30)

      let aliceReward = await rewards.getAvailableRewards(alice)
      expect(aliceReward).to.equal(10)
      let bobRewards = await rewards.getAvailableRewards(bob)
      expect(bobRewards).to.equal(10)
      let carolRewards = await rewards.getAvailableRewards(carol)
      expect(carolRewards).to.equal(10)

      // Alice withdraws her rewards
      // Alice: 0; Bob: 10; Carol: 10
      await rewards.withdrawRewards(alice)

      aliceReward = await rewards.getAvailableRewards(alice)
      expect(aliceReward).to.equal(0)
      bobRewards = await rewards.getAvailableRewards(bob)
      expect(bobRewards).to.equal(10)
      carolRewards = await rewards.getAvailableRewards(carol)
      expect(carolRewards).to.equal(10)

      // Reward to all
      // Alice: 10; Bob: 20; Carol: 20
      await rewards.payReward(30)

      aliceReward = await rewards.getAvailableRewards(alice)
      expect(aliceReward).to.equal(10)
      bobRewards = await rewards.getAvailableRewards(bob)
      expect(bobRewards).to.equal(20)
      carolRewards = await rewards.getAvailableRewards(carol)
      expect(carolRewards).to.equal(20)

      // Bob goes ineligible.
      await rewards.makeIneligible(bob, 10)

      // Reward to all
      // Alice: 20; Bob: 20; Carol: 30
      await rewards.payReward(30)

      aliceReward = await rewards.getAvailableRewards(alice)
      expect(aliceReward).to.equal(20)
      bobRewards = await rewards.getAvailableRewards(bob)
      expect(bobRewards).to.equal(20)
      carolRewards = await rewards.getAvailableRewards(carol)
      expect(carolRewards).to.equal(30)

      // Bob and Carol withdraws their rewards
      // Alice: 20; Bob: 0; Carol: 0
      await rewards.withdrawRewards(bob)
      await rewards.withdrawRewards(carol)

      aliceReward = await rewards.getAvailableRewards(alice)
      expect(aliceReward).to.equal(20)
      bobRewards = await rewards.getAvailableRewards(bob)
      expect(bobRewards).to.equal(0)
      carolRewards = await rewards.getAvailableRewards(carol)
      expect(carolRewards).to.equal(0)
    })
  })
})
