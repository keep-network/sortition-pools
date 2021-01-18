const Branch = artifacts.require("Branch")
const Position = artifacts.require("Position")
const StackLib = artifacts.require("StackLib")
const Leaf = artifacts.require("Leaf")
const SortitionPool = artifacts.require("./contracts/SortitionPool.sol")
const StakingContractStub = artifacts.require("StakingContractStub.sol")

const {mineBlocks} = require("./mineBlocks")

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
    SortitionPool.link(StackLib)
    SortitionPool.link(Leaf)
    staking = await StakingContractStub.new()
    pool = await SortitionPool.new(
      staking.address,
      minStake,
      poolWeightDivisor,
      owner,
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

      await mineBlocks(11)

      const group = await pool.selectGroup.call(3, seed, minStake, {
        from: owner,
      })
      await pool.selectGroup(3, seed, minStake, {from: owner})

      assert.equal(group.length, 3)
    })

    it("reverts when called by non-owner", async () => {
      await staking.setStake(alice, 20000)
      await staking.setStake(bob, 22000)
      await staking.setStake(carol, 24000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)
      await pool.joinPool(carol)

      await mineBlocks(11)

      try {
        await pool.selectGroup.call(3, seed, minStake, {from: accounts[0]})
      } catch (error) {
        assert.include(error.message, "Only owner may select groups")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("reverts when there are no operators in pool", async () => {
      try {
        await pool.selectGroup.call(3, seed, minStake, {from: owner})
      } catch (error) {
        assert.include(error.message, "Not enough operators in pool")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("returns group of expected size if less operators are registered", async () => {
      await staking.setStake(alice, 2000)
      await pool.joinPool(alice)

      await mineBlocks(11)

      const group = await pool.selectGroup.call(5, seed, minStake, {
        from: owner,
      })
      await pool.selectGroup(5, seed, minStake, {from: owner})
      assert.equal(group.length, 5)
    })

    it("removes ineligible operators", async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 4000000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, 1000)

      await mineBlocks(11)

      const group = await pool.selectGroup.call(5, seed, minStake, {
        from: owner,
      })
      await pool.selectGroup(5, seed, minStake, {from: owner})
      assert.deepEqual(group, [alice, alice, alice, alice, alice])
    })

    it("removes outdated but still operators", async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 4000000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, 390000)

      await mineBlocks(11)

      const group = await pool.selectGroup.call(5, seed, minStake, {
        from: owner,
      })
      await pool.selectGroup(5, seed, minStake, {from: owner})
      assert.deepEqual(group, [alice, alice, alice, alice, alice])
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

      const group = await pool.selectGroup.call(5, seed, minStake, {
        from: owner,
      })
      await pool.selectGroup(5, seed, minStake, {from: owner})
      assert.deepEqual(group, [bob, bob, bob, bob, bob])
    })

    it("ignores too recently added operators", async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 2000)
      await pool.joinPool(alice)

      await mineBlocks(11)

      await pool.joinPool(bob)

      const group = await pool.selectGroup.call(5, seed, minStake, {
        from: owner,
      })
      await pool.selectGroup(5, seed, minStake, {from: owner})
      assert.deepEqual(group, [alice, alice, alice, alice, alice])

      await mineBlocks(11)
      await staking.setStake(alice, 1000)

      const group2 = await pool.selectGroup.call(5, seed, minStake, {
        from: owner,
      })
      await pool.selectGroup(5, seed, minStake, {from: owner})
      assert.deepEqual(group2, [bob, bob, bob, bob, bob])
    })

    it("can select really large groups efficiently", async () => {
      for (i = 101; i < 150; i++) {
        const address = "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + i.toString()
        await staking.setStake(address, minStake * i)
        await pool.joinPool(address)
      }

      await mineBlocks(11)

      const group = await pool.selectGroup.call(100, seed, minStake, {
        from: owner,
      })
      await pool.selectGroup(100, seed, minStake, {from: owner})
      assert.equal(group.length, 100)
    })
  })

  describe("selectSetGroup", async () => {
    it("works", async () => {
      const nOperators = 1000
      const nSelected = 100
      for (i = 1010; i < 1010 + nOperators; i++) {
        const address = "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + i.toString()
        await staking.setStake(address, minStake * i)
        await pool.joinPool(address)
      }

      await mineBlocks(11)

      const group = await pool.selectSetGroup.call(nSelected, seed, minStake, {
        from: owner,
      })
      const tx = await pool.selectSetGroup(nSelected, seed, minStake, {
        from: owner,
      })
      assert.equal(group.length, nSelected)
      const gasUsed = tx.receipt.gasUsed
      console.log("Number of operators: " + nOperators)
      console.log("Number selected: " + nSelected)
      console.log("Total gas: " + gasUsed)
      console.log("Gas per member: " + gasUsed / nSelected)
      assert.equal(gasUsed < 8000000, true)
    })
  })
})
