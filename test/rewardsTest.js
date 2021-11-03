const RewardsStub = artifacts.require("RewardsStub.sol")

contract("Rewards", (accounts) => {
  let rewards
  const alice = accounts[0]
  const bob = accounts[1]

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
  })
})
