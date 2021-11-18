const RewardsStub = artifacts.require("RewardsStub.sol")

const { time } = require("@openzeppelin/test-helpers")

contract.only("Rewards", (accounts) => {
  let rewards
  const alice = accounts[0]
  const bob = accounts[1]
  const carol = accounts[2]

  before(async () => {})

  beforeEach(async () => {
    rewards = await RewardsStub.new()
  })

  describe("sortition pool rewards", async () => {
    it("pays rewards proportionally", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      const poolWeight = await rewards.getPoolWeight.call()

      assert.equal(poolWeight, 100)

      await rewards.payReward(1000)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards.call(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards.call(bob)

      assert.equal(aliceRewards.toNumber(), 100)
      assert.equal(bobRewards.toNumber(), 900)
    })

    it("only pays to present members", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      await rewards.updateOperatorWeight(bob, 0)

      await rewards.payReward(1000)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards.call(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards.call(bob)

      assert.equal(aliceRewards.toNumber(), 1000)
      assert.equal(bobRewards.toNumber(), 0)
    })

    it("handles dust", async () => {
      await rewards.addOperator(alice, 10)

      await rewards.payReward(123)

      const acc1 = await rewards.getGlobalAccumulator.call()
      assert.equal(acc1.toNumber(), 12)

      const dust1 = await rewards.getRoundingDust.call()
      assert.equal(dust1.toNumber(), 3)

      await rewards.addOperator(bob, 20)

      await rewards.payReward(987)

      const acc2 = await rewards.getGlobalAccumulator.call()
      assert.equal(acc2.toNumber(), 45)

      const dust2 = await rewards.getRoundingDust.call()
      assert.equal(dust2.toNumber(), 0)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards.call(alice)

      assert.equal(aliceRewards.toNumber(), 450)

      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards.call(bob)

      assert.equal(bobRewards.toNumber(), 660)
    })

    it("handles sequences", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      // alice: 100; bob: 900
      await rewards.payReward(1000)

      const globalAcc1 = await rewards.getGlobalAccumulator.call()
      assert.equal(globalAcc1.toNumber(), 10)

      await rewards.updateOperatorWeight(bob, 0)

      const bobRew1 = await rewards.getAccruedRewards.call(bob)
      assert.equal(bobRew1.toNumber(), 900)

      const bobAcc1 = await rewards.getAccumulator.call(bob)
      assert.equal(bobAcc1.toNumber(), 10)

      const aliceAcc1 = await rewards.getAccumulator.call(alice)
      assert.equal(aliceAcc1.toNumber(), 0)

      // alice: 1000; bob: 0
      // alice total: 1100; bob total: 900
      await rewards.payReward(1000)

      const globalAcc2 = await rewards.getGlobalAccumulator.call()
      assert.equal(globalAcc2.toNumber(), 110)

      await rewards.updateOperatorWeight(bob, 40)

      const bobRew2 = await rewards.getAccruedRewards.call(bob)
      assert.equal(bobRew2.toNumber(), 900)

      const bobAcc2 = await rewards.getAccumulator.call(bob)
      assert.equal(bobAcc2.toNumber(), 110)

      const aliceAcc2 = await rewards.getAccumulator.call(alice)
      assert.equal(aliceAcc2.toNumber(), 0)

      // alice: 200; bob: 800
      // alice total: 1300; bob total: 1700
      await rewards.payReward(1000)

      const globalAcc3 = await rewards.getGlobalAccumulator.call()
      assert.equal(globalAcc3.toNumber(), 130)

      const bobRew3 = await rewards.getAccruedRewards.call(bob)
      assert.equal(bobRew3.toNumber(), 900)

      const bobAcc3 = await rewards.getAccumulator.call(bob)
      assert.equal(bobAcc3.toNumber(), 110)

      const aliceAcc3 = await rewards.getAccumulator.call(alice)
      assert.equal(aliceAcc3.toNumber(), 0)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards.call(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards.call(bob)

      assert.equal(aliceRewards.toNumber(), 1300)
      assert.equal(bobRewards.toNumber(), 1700)
    })

    it("permits making operators ineligible", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      // Reward to both
      // Alice: 10; Bob: 90
      await rewards.payReward(100)

      await rewards.makeIneligible(bob, 10)

      const iWeight = await rewards.getIneligibleWeight.call()
      assert.equal(iWeight.toNumber(), 90)

      // Reward only to Alice
      // Alice: 110; Bob: 90
      await rewards.payReward(100)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards.call(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards.call(bob)

      assert.equal(aliceRewards.toNumber(), 110)
      assert.equal(bobRewards.toNumber(), 90)
    })

    it("permits making multiple operators ineligible", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 10)
      await rewards.addOperator(carol, 10)

      // Reward to all
      // Alice: 10; Bob: 10; Carol: 10
      await rewards.payReward(30)

      await rewards.massMakeIneligible([bob, carol], 10)

      const iWeight = await rewards.getIneligibleWeight.call()
      assert.equal(iWeight.toNumber(), 20)

      // Reward only to Alice
      // Alice: 40; Bob: 10; Carol: 10
      await rewards.payReward(30)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards.call(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards.call(bob)
      await rewards.withdrawRewards(carol)
      const carolRewards = await rewards.getWithdrawnRewards.call(carol)

      assert.equal(aliceRewards.toNumber(), 40)
      assert.equal(bobRewards.toNumber(), 10)
      assert.equal(carolRewards.toNumber(), 10)
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

      await time.increase(11)

      await rewards.makeEligible(bob)

      const iWeight = await rewards.getIneligibleWeight.call()
      assert.equal(iWeight.toNumber(), 0)

      // Reward to both
      // Alice: 120; Bob: 180
      await rewards.payReward(100)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards.call(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards.call(bob)

      assert.equal(aliceRewards.toNumber(), 120)
      assert.equal(bobRewards.toNumber(), 180)
    })

    it("won't restore eligibility prematurely", async () => {
      await rewards.addOperator(alice, 10)

      await rewards.makeIneligible(alice, 10)

      try {
        await rewards.makeEligible(alice)
      } catch (error) {
        assert.include(error.message, "Operator still ineligible")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("permits changing ineligible operator weight", async () => {
      await rewards.addOperator(alice, 10)
      await rewards.addOperator(bob, 90)

      await rewards.makeIneligible(bob, 10)

      await rewards.updateOperatorWeight(bob, 40)

      const iWeight = await rewards.getIneligibleWeight.call()
      assert.equal(iWeight.toNumber(), 40)

      // Reward only to Alice
      // Alice: 100; Bob: 0
      await rewards.payReward(100)

      await time.increase(11)

      await rewards.makeEligible(bob)

      // Reward to both
      // Alice: 120; Bob: 80
      await rewards.payReward(100)

      await rewards.withdrawRewards(alice)
      const aliceRewards = await rewards.getWithdrawnRewards.call(alice)
      await rewards.withdrawRewards(bob)
      const bobRewards = await rewards.getWithdrawnRewards.call(bob)

      assert.equal(aliceRewards.toNumber(), 120)
      assert.equal(bobRewards.toNumber(), 80)
    })

    it("handles lengthening ineligibility", async () => {
      await rewards.addOperator(alice, 10)

      await rewards.makeIneligible(alice, 10)
      await rewards.makeIneligible(alice, 100)

      await time.increase(11)

      try {
        await rewards.makeEligible(alice)
      } catch (error) {
        assert.include(error.message, "Operator still ineligible")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("won't shorten ineligibility", async () => {
      await rewards.addOperator(alice, 10)

      await rewards.makeIneligible(alice, 100)
      await rewards.makeIneligible(alice, 10)

      await time.increase(11)

      try {
        await rewards.makeEligible(alice)
      } catch (error) {
        assert.include(error.message, "Operator still ineligible")
        return
      }

      assert.fail("Expected throw not received")
    })
  })
})
