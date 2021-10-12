const Branch = artifacts.require("Branch")
const Position = artifacts.require("Position")
const StackLib = artifacts.require("StackLib")
const Leaf = artifacts.require("Leaf")
const FullyBackedSortitionPool = artifacts.require("FullyBackedSortitionPool")

const FullyBackedBondingStub = artifacts.require("FullyBackedBondingStub")

const { mineBlocks } = require("./mineBlocks")

const { expectRevert } = require("@openzeppelin/test-helpers")

const BN = web3.utils.BN

const chai = require("chai")
chai.use(require("bn-chai")(BN))
const expect = chai.expect

contract("FullyBackedSortitionPool", (accounts) => {
  const seed = "0xff39d6cca87853892d2854566e883008bc"

  const weightDivisor = web3.utils.toBN(1000)
  const minimumBondableValue = weightDivisor.muln(5)
  const bond = minimumBondableValue.muln(2)

  const alice = accounts[1]
  const bob = accounts[2]
  const carol = accounts[3]
  const david = accounts[4]
  const emily = accounts[5]
  const owner = accounts[9]

  let pool
  let bonding
  let prepareOperator
  let operatorInitBlocks

  beforeEach(async () => {
    await FullyBackedSortitionPool.link(Branch)
    await FullyBackedSortitionPool.link(Position)
    await FullyBackedSortitionPool.link(StackLib)
    await FullyBackedSortitionPool.link(Leaf)
    bonding = await FullyBackedBondingStub.new()

    prepareOperator = async (address, bondableValue) => {
      await bonding.setBondableValue(address, bondableValue)
      await bonding.setInitialized(address, true)

      await pool.joinPool(address)
    }

    pool = await FullyBackedSortitionPool.new(
      bonding.address,
      minimumBondableValue,
      weightDivisor,
      owner,
    )

    operatorInitBlocks = await pool.operatorInitBlocks()
  })

  describe("isOperatorInitialized", async () => {
    it("reverts if operator is not in the pool", async () => {
      expectRevert(
        pool.isOperatorInitialized(alice),
        "Operator is not in the pool",
      )
    })

    it("returns false at the beginning of the initialization period", async () => {
      await prepareOperator(alice, bond)

      assert.isFalse(
        await pool.isOperatorInitialized(alice),
        "incorrect result at the beginning of the period",
      )
    })

    it("returns false when the initialization period is almost passed", async () => {
      await prepareOperator(alice, bond)

      await mineBlocks(operatorInitBlocks)

      assert.isFalse(
        await pool.isOperatorInitialized(alice),
        "incorrect result when period almost passed",
      )
    })

    it("returns true when initialization period passed", async () => {
      await prepareOperator(alice, bond)

      await mineBlocks(operatorInitBlocks.addn(1))

      assert.isTrue(await pool.isOperatorInitialized(alice))
    })

    it("reverts when operator gets banned in the pool", async () => {
      await prepareOperator(alice, bond)

      await mineBlocks(operatorInitBlocks.addn(1))

      await pool.ban(alice, { from: owner })

      expectRevert(
        pool.isOperatorInitialized(alice),
        "Operator is not in the pool",
      )
    })
  })

  describe("selectSetGroup", async () => {
    it("returns group of expected size with unique members", async () => {
      await prepareOperator(alice, bond)
      await prepareOperator(bob, bond)
      await prepareOperator(carol, bond)
      await prepareOperator(david, bond)
      await prepareOperator(emily, bond)

      await mineBlocks(operatorInitBlocks.addn(1))

      let group

      group = await pool.selectSetGroup.call(3, seed, minimumBondableValue, {
        from: owner,
      })
      await pool.selectSetGroup(3, seed, minimumBondableValue, { from: owner })
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      group = await pool.selectSetGroup.call(5, seed, minimumBondableValue, {
        from: owner,
      })
      await pool.selectSetGroup(5, seed, minimumBondableValue, { from: owner })
      assert.equal(group.length, 5)
      assert.isFalse(hasDuplicates(group))
    })

    it("updates operators' weight", async () => {
      await prepareOperator(alice, bond)
      await prepareOperator(bob, bond.muln(2))
      await prepareOperator(carol, bond.muln(3))

      await mineBlocks(operatorInitBlocks.addn(1))

      expect(await pool.getPoolWeight(alice)).to.eq.BN(bond.div(weightDivisor))
      expect(await pool.getPoolWeight(bob)).to.eq.BN(
        bond.muln(2).div(weightDivisor),
      )
      expect(await pool.getPoolWeight(carol)).to.eq.BN(
        bond.muln(3).div(weightDivisor),
      )

      await pool.selectSetGroup(3, seed, minimumBondableValue, { from: owner })

      expect(await pool.getPoolWeight(alice)).to.eq.BN(
        bond.sub(minimumBondableValue).div(weightDivisor),
      )
      expect(await pool.getPoolWeight(bob)).to.eq.BN(
        bond.muln(2).sub(minimumBondableValue).div(weightDivisor),
      )
      expect(await pool.getPoolWeight(carol)).to.eq.BN(
        bond.muln(3).sub(minimumBondableValue).div(weightDivisor),
      )
    })

    it("reverts when called by non-owner", async () => {
      await prepareOperator(alice, bond)
      await prepareOperator(bob, bond)
      await prepareOperator(carol, bond)

      await mineBlocks(operatorInitBlocks.addn(1))

      await expectRevert(
        pool.selectSetGroup(3, seed, minimumBondableValue, { from: alice }),
        "Caller is not the owner",
      )
    })

    it("reverts when there are no operators in pool", async () => {
      await expectRevert(
        pool.selectSetGroup(3, seed, minimumBondableValue, { from: owner }),
        "Not enough operators in pool",
      )
    })

    it("reverts when there are not enough operators in pool", async () => {
      await prepareOperator(alice, bond)
      await prepareOperator(bob, bond)

      await mineBlocks(operatorInitBlocks.addn(1))

      await expectRevert(
        pool.selectSetGroup(3, seed, minimumBondableValue, { from: owner }),
        "Not enough operators in pool",
      )
    })

    it("reverts when operator is not initialized in the sortition pool", async () => {
      // Register two operators.
      await prepareOperator(alice, bond)
      await prepareOperator(bob, bond)

      assert.equal(await pool.operatorsInPool(), 2)

      // Initialization period not passed.
      await expectRevert(
        pool.selectSetGroup(2, seed, minimumBondableValue, { from: owner }),
        "Not enough operators in pool",
      )

      // Initialization period passed.
      await mineBlocks(operatorInitBlocks.addn(1))

      await pool.selectSetGroup(2, seed, minimumBondableValue, { from: owner })

      // Register third operator.
      await prepareOperator(carol, bond)

      assert.equal(
        await pool.operatorsInPool(),
        3,
        "incorrect number of operators after second registration",
      )

      await expectRevert(
        pool.selectSetGroup(3, seed, minimumBondableValue, { from: owner }),
        "Not enough operators in pool",
        "unexpected result for the third group selection",
      )

      await mineBlocks(operatorInitBlocks.addn(1))

      await pool.selectSetGroup(3, seed, minimumBondableValue, { from: owner })
    })

    it("reverts when operator gets banned in the sortition pool", async () => {
      // Register three operators.
      await prepareOperator(alice, bond)
      await prepareOperator(bob, bond)
      await prepareOperator(carol, bond)

      assert.equal(await pool.operatorsInPool(), 3)

      // Initialization period passed.
      await mineBlocks(operatorInitBlocks.addn(1))

      await pool.selectSetGroup(2, seed, minimumBondableValue, { from: owner })

      // Ban an operator.
      await pool.ban(carol, { from: owner })

      assert.equal(
        await pool.operatorsInPool(),
        2,
        "incorrect number of operators after operator ban",
      )

      await expectRevert(
        pool.selectSetGroup(3, seed, minimumBondableValue, { from: owner }),
        "Not enough operators in pool",
      )
    })

    it("removes minimum-bond-ineligible operators and still works afterwards", async () => {
      await prepareOperator(alice, bond)
      await prepareOperator(bob, bond)
      await prepareOperator(carol, bond.muln(100))
      await prepareOperator(david, bond)

      await mineBlocks(operatorInitBlocks.addn(1))

      await bonding.setBondableValue(carol, minimumBondableValue.subn(1))

      // all 4 operators in the pool
      assert.equal(await pool.operatorsInPool(), 4)

      // should select group and remove carol
      await pool.selectSetGroup(3, seed, bond, { from: owner })

      assert.equal(await pool.operatorsInPool(), 3) // carol removed

      // should have only 3 operators in the pool now
      group = await pool.selectSetGroup.call(3, seed, bond, {
        from: owner,
      })

      assert.equal(group.length, 3)
      assert.sameMembers(group, [alice, bob, david])
      assert.equal(await pool.operatorsInPool(), 3)
    })

    it("skips selection-bond-ineligible operators and still works afterwards", async () => {
      await prepareOperator(alice, bond)
      await prepareOperator(bob, bond.subn(1))
      await prepareOperator(carol, bond)
      await prepareOperator(david, bond)

      await mineBlocks(operatorInitBlocks.addn(1))

      // all 4 operators in the pool
      assert.equal(await pool.operatorsInPool(), 4)

      // should select group and skip bob (do not remove it!)
      await pool.selectSetGroup(3, seed, bond, { from: owner })

      // all 4 operators still in the pool
      assert.equal(await pool.operatorsInPool(), 4)

      group = await pool.selectSetGroup.call(
        3,
        seed,
        minimumBondableValue.muln(2),
        {
          from: owner,
        },
      )

      assert.equal(group.length, 3)
      assert.sameMembers(group, [alice, carol, david])
      assert.equal(await pool.operatorsInPool(), 4)
    })

    it("updates operators whose weight has increased", async () => {
      await prepareOperator(alice, bond)
      await prepareOperator(bob, bond)
      await prepareOperator(carol, bond)
      await prepareOperator(david, bond)

      await mineBlocks(operatorInitBlocks.addn(1))

      // Insignificant changes less than the weight divisor, resulting in no weight update.
      await bonding.setBondableValue(alice, bond.addn(1))
      await bonding.setBondableValue(bob, bond.add(weightDivisor).subn(1))
      // The first value resulting in the weight update.
      await bonding.setBondableValue(carol, bond.add(weightDivisor))
      // Value increasing the weight for couple units.
      await bonding.setBondableValue(david, bond.add(weightDivisor.muln(7)))

      group = await pool.selectSetGroup.call(4, seed, minimumBondableValue, {
        from: owner,
      })
      await pool.selectSetGroup(4, seed, minimumBondableValue, { from: owner })
      assert.equal(group.length, 4)
      assert.isFalse(hasDuplicates(group))

      expect(await pool.getPoolWeight(alice)).to.eq.BN(
        bond.sub(minimumBondableValue).div(weightDivisor),
      )
      expect(await pool.getPoolWeight(bob)).to.eq.BN(
        bond.sub(minimumBondableValue).div(weightDivisor),
      )
      expect(await pool.getPoolWeight(carol)).to.eq.BN(
        bond.sub(minimumBondableValue).div(weightDivisor).addn(1),
      )
      expect(await pool.getPoolWeight(david)).to.eq.BN(
        bond.sub(minimumBondableValue).div(weightDivisor).addn(7),
      )
    })

    function hasDuplicates(array) {
      return new Set(array).size !== array.length
    }
  })

  describe("setMinimumBondableValue", async () => {
    it("default value set in the pool constructor", async () => {
      expect(await pool.getMinimumBondableValue()).to.eq.BN(
        minimumBondableValue,
      )
    })

    it("can only be called by the owner", async () => {
      await expectRevert(
        pool.setMinimumBondableValue(1, { from: accounts[0] }),
        "Only owner may update minimum bond value",
      )
    })

    it("updates the minimum bondable value", async () => {
      await pool.setMinimumBondableValue(1, { from: owner })
      expect(await pool.getMinimumBondableValue()).to.eq.BN(1)

      await pool.setMinimumBondableValue(6, { from: owner })
      expect(await pool.getMinimumBondableValue()).to.eq.BN(6)
    })
  })

  describe("joinPool", async () => {
    it("succeeds with minimum bond value", async () => {
      await bonding.setBondableValue(alice, minimumBondableValue)
      await bonding.setInitialized(alice, true)

      await pool.joinPool(alice)

      expect(await pool.getPoolWeight(alice)).to.eq.BN(
        minimumBondableValue.div(weightDivisor),
      )
    })

    it("fails with less than minimum bond value", async () => {
      await bonding.setBondableValue(alice, minimumBondableValue.subn(1))
      await bonding.setInitialized(alice, true)

      await expectRevert(pool.joinPool(alice), "Operator not eligible")
    })

    it("reverts if the operator is not yet initialized in the bonding contract", async () => {
      await bonding.setBondableValue(alice, minimumBondableValue)
      await bonding.setInitialized(alice, false)

      await expectRevert(pool.joinPool(alice), "Operator not eligible")
    })

    it("reverts if operator is already registered", async () => {
      await bonding.setBondableValue(alice, minimumBondableValue)
      await bonding.setInitialized(alice, true)

      await pool.joinPool(alice)

      await expectRevert(
        pool.joinPool(alice),
        "Operator is already registered in the pool",
      )
    })

    it("fails for banned operator", async () => {
      await pool.ban(alice, { from: owner })

      await bonding.setBondableValue(alice, minimumBondableValue)
      await bonding.setInitialized(alice, true)

      await expectRevert(pool.joinPool(alice), "Operator not eligible")
    })
  })

  describe("ban", async () => {
    it("adds operator to banned operators", async () => {
      expect(await pool.bannedOperators(alice)).to.be.false

      await pool.ban(alice, { from: owner })

      expect(await pool.bannedOperators(alice)).to.be.true
    })

    it("does not revert when called multiple times", async () => {
      expect(await pool.bannedOperators(alice)).to.be.false

      await pool.ban(alice, { from: owner })
      await pool.ban(alice, { from: owner })

      expect(await pool.bannedOperators(alice)).to.be.true
    })

    it("does not revert when operator is not registered", async () => {
      expect(await pool.isOperatorRegistered(alice)).to.be.false

      await pool.ban(alice, { from: owner })
    })

    it("removes operator from the pool", async () => {
      await bonding.setBondableValue(alice, minimumBondableValue)
      await bonding.setInitialized(alice, true)
      await pool.joinPool(alice)

      expect(await pool.isOperatorRegistered(alice)).to.be.true

      await pool.ban(alice, { from: owner })

      expect(await pool.isOperatorRegistered(alice)).to.be.false
      expect(await pool.isOperatorInPool(alice)).to.be.false
      expect(await pool.getPoolWeight(alice)).to.eq.BN(0)
    })

    it("reverts when called by non-owner", async () => {
      await expectRevert(pool.ban(alice), "Caller is not the owner")
    })
  })
})
