const Branch = artifacts.require("Branch")
const Position = artifacts.require("Position")
const Leaf = artifacts.require("Leaf")
const SortitionPool = artifacts.require("./contracts/SortitionPool.sol")
const SortitionPoolStub = artifacts.require("./contracts/SortitionPoolStub.sol")
const TokenStub = artifacts.require("./contracts/TokenStub.sol")
const StakingContractStub = artifacts.require("StakingContractStub.sol")

const { time } = require("@openzeppelin/test-helpers")
const { mineBlocks } = require("./mineBlocks")

contract.only("SortitionPool", (accounts) => {
  const seed = "0xff39d6cca87853892d2854566e883008bc"
  const minStake = 2000
  const poolWeightDivisor = 2000
  let token
  let staking
  let pool
  const alice = accounts[0]
  const bob = accounts[1]
  const carol = accounts[2]
  const owner = accounts[9]

  beforeEach(async () => {
    SortitionPool.link(Branch)
    SortitionPool.link(Position)
    SortitionPool.link(Leaf)
    token = await TokenStub.new()
    staking = await StakingContractStub.new()
    pool = await SortitionPoolStub.new(
      staking.address,
      minStake,
      poolWeightDivisor,
      owner,
      token.address,
    )
  })

  describe("selectGroup", async () => {
    it("returns group of expected size", async () => {
      await staking.setStake(alice, 20000)
      await staking.setStake(bob, 22000)
      await staking.setStake(carol, 24000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)
      await pool.joinPool(carol)

      const group = await pool.selectGroup(3, seed, {
        from: owner,
      })
      await pool.nonViewSelectGroup(3, seed, { from: owner })

      assert.equal(group.length, 3)
    })

    it("reverts when called by non-owner", async () => {
      await staking.setStake(alice, 20000)
      await staking.setStake(bob, 22000)
      await staking.setStake(carol, 24000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)
      await pool.joinPool(carol)

      try {
        await pool.selectGroup(3, seed, { from: accounts[0] })
      } catch (error) {
        assert.include(error.message, "Only owner may select groups")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("reverts when there are no operators in pool", async () => {
      try {
        await pool.selectGroup(3, seed, { from: owner })
      } catch (error) {
        assert.include(error.message, "Not enough operators in pool")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("returns group of expected size if less operators are registered", async () => {
      await staking.setStake(alice, 2000)
      await pool.joinPool(alice)

      const group = await pool.selectGroup(5, seed, {
        from: owner,
      })
      await pool.nonViewSelectGroup(5, seed, { from: owner })
      assert.equal(group.length, 5)
    })

    it("does not remove ineligible operators", async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 4000000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, 1000)

      const group = await pool.selectGroup(5, seed, {
        from: owner,
      })
      await pool.nonViewSelectGroup(5, seed, { from: owner })
      assert.equal(group.length, 5)
    })

    it("does not remove outdated but eligible operators", async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 4000000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, 390000)

      const group = await pool.selectGroup(5, seed, {
        from: owner,
      })
      await pool.nonViewSelectGroup(5, seed, { from: owner })
      assert.equal(group.length, 5)
    })

    it("lets outdated operators update their status", async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 4000000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, 390000)
      await staking.setStake(alice, 1000)

      await mineBlocks(11)

      await pool.updateOperatorStatus(bob)
      await pool.updateOperatorStatus(alice)

      const group = await pool.selectGroup(5, seed, {
        from: owner,
      })
      await pool.nonViewSelectGroup(5, seed, { from: owner })
      assert.deepEqual(group, [bob, bob, bob, bob, bob])
    })

    it("can select really large groups efficiently", async () => {
      for (i = 101; i < 150; i++) {
        const address = "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + i.toString()
        await staking.setStake(address, minStake * i)
        await pool.joinPool(address)
      }

      const group = await pool.selectGroup(100, seed, {
        from: owner,
      })
      await pool.nonViewSelectGroup(100, seed, { from: owner })
      assert.equal(group.length, 100)
    })
  })

  describe("pool rewards", async () => {
    it("pays rewards correctly", async () => {
      await token.mint(owner, 1000)
      await staking.setStake(alice, 10000)
      await staking.setStake(bob, 20000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)
      await token.approveAndCall(pool.address, 300, [], { from: owner })
      await pool.withdrawRewards(alice)
      await pool.withdrawRewards(bob)
      const aliceReward = await token.balanceOf(alice)
      const bobReward = await token.balanceOf(bob)
      assert.equal(aliceReward.toNumber(), 100)
      assert.equal(bobReward.toNumber(), 200)
    })

    it("doesn't pay to ineligible operators", async () => {
      await token.mint(owner, 1000)
      await staking.setStake(alice, 10000)
      await staking.setStake(bob, 20000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)
      const now = await time.latest()
      await pool.setRewardIneligibility([bob], now + 100, { from: owner })
      await token.approveAndCall(pool.address, 300, [], { from: owner })
      await pool.withdrawRewards(alice)
      await pool.withdrawRewards(bob)
      const aliceReward = await token.balanceOf(alice)
      const bobReward = await token.balanceOf(bob)
      assert.equal(aliceReward.toNumber(), 300)
      assert.equal(bobReward.toNumber(), 0)
    })

    it("sets operator ineligibility correctly", async () => {
      await token.mint(owner, 1000)
      await staking.setStake(alice, 10000)
      await staking.setStake(bob, 20000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)
      const now = await time.latest()
      await pool.setRewardIneligibility([bob], now + 100, { from: owner })
      try {
        await pool.restoreRewardEligibility(bob)
      } catch (error) {
        assert.include(error.message, "Operator still ineligible")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("can set many operators ineligible", async () => {
      const evens = []
      for (i = 101; i < 150; i++) {
        const address = "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + i.toString()
        await staking.setStake(address, minStake * i)
        await pool.joinPool(address)
        if (i % 2 == 0) {
          evens.push(address)
        }
      }

      const now = await time.latest()
      await pool.setRewardIneligibility(evens, now + 100, { from: owner })

      const group = await pool.selectGroup(100, seed, {
        from: owner,
      })
      await pool.nonViewSelectGroup(100, seed, { from: owner })
      assert.equal(group.length, 100)
    })
  })
})
