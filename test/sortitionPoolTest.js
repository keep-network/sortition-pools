const Branch = artifacts.require("Branch")
const Position = artifacts.require("Position")
const Leaf = artifacts.require("Leaf")
const SortitionPool = artifacts.require("./contracts/SortitionPool.sol")
const SortitionPoolStub = artifacts.require("./contracts/SortitionPoolStub.sol")
const StakingContractStub = artifacts.require("StakingContractStub.sol")

const { mineBlocks } = require("./mineBlocks")

contract("SortitionPool", (accounts) => {
  const seed = "0xff39d6cca87853892d2854566e883008bc"
  const minStake = 2000
  const poolWeightDivisor = 2000
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
    staking = await StakingContractStub.new()
    pool = await SortitionPoolStub.new(
      staking.address,
      minStake,
      poolWeightDivisor,
      owner,
    )
  })

  describe("insertOperator", async () => {
    it("inserts the operator to the pool if called by the owner", async () => {
      await staking.setStake(alice, 20000)
      await pool.insertOperator(alice, { from: owner })

      assert.equal(await pool.isOperatorInPool(alice), true)
    })

    it("reverts if called by a non-owner", async () => {
      await staking.setStake(alice, 20000)

      try {
        await pool.insertOperator(alice, { from: alice })
      } catch (error) {
        assert.include(error.message, "Caller is not the owner")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("reverts if operator is not eligible", async () => {
      try {
        await pool.insertOperator(alice, { from: owner })
      } catch (error) {
        assert.include(error.message, "Operator not eligible")
        return
      }

      assert.fail("Expected throw not received")
    })
  })

  describe("removeOperator", async () => {
    it("removes the operator from the pool if called by the owner", async () => {
      await staking.setStake(alice, 20000)
      await pool.insertOperator(alice, { from: owner })

      await pool.removeOperator(alice, { from: owner })

      assert.equal(await pool.isOperatorInPool(alice), false)
    })

    it("reverts if called by a non-owner", async () => {
      await staking.setStake(alice, 20000)
      await pool.insertOperator(alice, { from: owner })

      try {
        await pool.removeOperator(alice, { from: alice })
      } catch (error) {
        assert.include(error.message, "Caller is not the owner")
        return
      }

      assert.fail("Expected throw not received")
    })
  })

  describe("selectGroup", async () => {
    it("returns group of expected size", async () => {
      await staking.setStake(alice, 20000)
      await staking.setStake(bob, 22000)
      await staking.setStake(carol, 24000)
      await pool.insertOperator(alice, { from: owner })
      await pool.insertOperator(bob, { from: owner })
      await pool.insertOperator(carol, { from: owner })

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
      await pool.insertOperator(alice, { from: owner })
      await pool.insertOperator(bob, { from: owner })
      await pool.insertOperator(carol, { from: owner })

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
      await pool.insertOperator(alice, { from: owner })

      const group = await pool.selectGroup(5, seed, {
        from: owner,
      })
      await pool.nonViewSelectGroup(5, seed, { from: owner })
      assert.equal(group.length, 5)
    })

    it("does not remove ineligible operators", async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 4000000)
      await pool.insertOperator(alice, { from: owner })
      await pool.insertOperator(bob, { from: owner })

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
      await pool.insertOperator(alice, { from: owner })
      await pool.insertOperator(bob, { from: owner })

      await staking.setStake(bob, 390000)

      const group = await pool.selectGroup(5, seed, {
        from: owner,
      })
      await pool.nonViewSelectGroup(5, seed, { from: owner })
      assert.equal(group.length, 5)
    })

    it("lets the owner to update outdated operators status", async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 4000000)
      await pool.insertOperator(alice, { from: owner })
      await pool.insertOperator(bob, { from: owner })

      await staking.setStake(bob, 390000)
      await staking.setStake(alice, 1000)

      await mineBlocks(11)

      await pool.updateOperatorStatus(bob, { from: owner })
      await pool.updateOperatorStatus(alice, { from: owner })

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
        await pool.insertOperator(address, { from: owner })
      }

      const group = await pool.selectGroup(100, seed, {
        from: owner,
      })
      await pool.nonViewSelectGroup(100, seed, { from: owner })
      assert.equal(group.length, 100)
    })
  })
})
