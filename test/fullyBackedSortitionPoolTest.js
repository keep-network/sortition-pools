const {accounts, contract} = require("@openzeppelin/test-environment")

const Branch = contract.fromArtifact("Branch")
const Position = contract.fromArtifact("Position")
const StackLib = contract.fromArtifact("StackLib")
const Leaf = contract.fromArtifact("Leaf")
const FullyBackedSortitionPool = contract.fromArtifact(
  "FullyBackedSortitionPool",
)

const BondingContractStub = contract.fromArtifact("BondingContractStub")

const {mineBlocks} = require("./helpers/mineBlocks")

const {expectRevert} = require("@openzeppelin/test-helpers")

const chai = require("chai")
const assert = chai.assert

describe("FullyBackedSortitionPool", () => {
  const seed = "0xff39d6cca87853892d2854566e883008bc"
  const bond = 2000
  const weightDivisor = 1000
  const alice = accounts[0]
  const bob = accounts[1]
  const carol = accounts[2]
  const david = accounts[3]
  const emily = accounts[4]
  const owner = accounts[9]
  let pool
  let bonding
  let prepareOperator

  beforeEach(async () => {
    await FullyBackedSortitionPool.detectNetwork()
    await FullyBackedSortitionPool.link("Branch", (await Branch.new()).address)
    await FullyBackedSortitionPool.link(
      "Position",
      (await Position.new()).address,
    )
    await FullyBackedSortitionPool.link(
      "StackLib",
      (await StackLib.new()).address,
    )
    await FullyBackedSortitionPool.link("Leaf", (await Leaf.new()).address)

    bonding = await BondingContractStub.new()

    prepareOperator = async (address, weight) => {
      await bonding.setBondableValue(address, weight * weightDivisor)
      await pool.joinPool(address)
    }

    pool = await FullyBackedSortitionPool.new(
      bonding.address,
      bond,
      weightDivisor,
      owner,
    )
  })

  describe("isOperatorInitialized", async () => {
    it("reverts if operator is not in the pool", async () => {
      expectRevert(
        pool.isOperatorInitialized(alice),
        "Operator is not in the pool",
      )
    })

    it("returns false at the beginning of the initialization period", async () => {
      await prepareOperator(alice, 10)

      assert.isFalse(
        await pool.isOperatorInitialized(alice),
        "incorrect result at the beginning of the period",
      )
    })

    it("returns false when the initialization period is almost passed", async () => {
      await prepareOperator(alice, 10)

      await mineBlocks(await pool.operatorInitBlocks())

      assert.isFalse(
        await pool.isOperatorInitialized(alice),
        "incorrect result when period almost passed",
      )
    })

    it("returns true when initialization period passed", async () => {
      await prepareOperator(alice, 10)

      await mineBlocks((await pool.operatorInitBlocks()).addn(1))

      assert.isTrue(await pool.isOperatorInitialized(alice))
    })
  })

  describe("selectSetGroup", async () => {
    it("returns group of expected size with unique members", async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)
      await prepareOperator(carol, 12)
      await prepareOperator(david, 13)
      await prepareOperator(emily, 14)

      await mineBlocks(11)

      let group

      group = await pool.selectSetGroup.call(3, seed, bond, {from: owner})
      await pool.selectSetGroup(3, seed, bond, {from: owner})
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      group = await pool.selectSetGroup.call(5, seed, bond, {from: owner})
      await pool.selectSetGroup(5, seed, bond, {from: owner})
      assert.equal(group.length, 5)
      assert.isFalse(hasDuplicates(group))
    })

    it("updates operators' weight", async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)
      await prepareOperator(carol, 12)

      await mineBlocks(11)

      assert.equal(await pool.getPoolWeight(alice), 10)
      assert.equal(await pool.getPoolWeight(bob), 11)
      assert.equal(await pool.getPoolWeight(carol), 12)

      await pool.selectSetGroup(3, seed, bond, {from: owner})

      assert.equal(await pool.getPoolWeight(alice), 8)
      assert.equal(await pool.getPoolWeight(bob), 9)
      assert.equal(await pool.getPoolWeight(carol), 10)
    })

    function hasDuplicates(array) {
      return new Set(array).size !== array.length
    }

    it("reverts when called by non-owner", async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)
      await prepareOperator(carol, 12)

      await mineBlocks(11)

      try {
        await pool.selectSetGroup(3, seed, bond, {from: alice})
      } catch (error) {
        assert.include(error.message, "Only owner may select groups")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("reverts when there are no operators in pool", async () => {
      try {
        await pool.selectSetGroup(3, seed, bond, {from: owner})
      } catch (error) {
        assert.include(error.message, "Not enough operators in pool")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("reverts when there are not enough operators in pool", async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)

      await mineBlocks(11)

      try {
        await pool.selectSetGroup(3, seed, bond, {from: owner})
      } catch (error) {
        assert.include(error.message, "Not enough operators in pool")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("removes ineligible operators and still works afterwards", async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)
      await prepareOperator(carol, 12)
      await prepareOperator(david, 5)

      await mineBlocks(11)

      await bonding.setBondableValue(carol, 1 * weightDivisor)

      try {
        await pool.selectSetGroup(4, seed, bond, {from: owner})
      } catch (error) {
        assert.include(error.message, "Not enough operators in pool")

        group = await pool.selectSetGroup.call(3, seed, bond, {from: owner})

        assert.equal(group.length, 3)
        assert.isFalse(hasDuplicates(group))

        return
      }

      assert.fail("Expected throw not received")
    })

    it("updates operators whose weight has increased", async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)
      await prepareOperator(carol, 12)

      await mineBlocks(11)

      await bonding.setBondableValue(carol, 15 * weightDivisor)

      group = await pool.selectSetGroup.call(3, seed, bond, {from: owner})
      await pool.selectSetGroup(3, seed, bond, {from: owner})
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      const postWeight = await pool.getPoolWeight(carol)
      assert.equal(postWeight, 13)
    })
  })
})
