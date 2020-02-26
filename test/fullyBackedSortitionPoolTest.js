const Branch = artifacts.require('Branch')
const Position = artifacts.require('Position')
const StackLib = artifacts.require('StackLib')
const Leaf = artifacts.require('Leaf')
const FullyBackedSortitionPool = artifacts.require('./contracts/FullyBackedSortitionPool.sol')

const BondingContractStub = artifacts.require('BondingContractStub.sol')

const { mineBlocks } = require('./mineBlocks')

const { expectRevert } = require('@openzeppelin/test-helpers')

contract('FullyBackedSortitionPool', (accounts) => {
  const seed = '0xff39d6cca87853892d2854566e883008bc'
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
    FullyBackedSortitionPool.link(Branch)
    FullyBackedSortitionPool.link(Position)
    FullyBackedSortitionPool.link(StackLib)
    FullyBackedSortitionPool.link(Leaf)
    bonding = await BondingContractStub.new()

    prepareOperator = async (address, weight) => {
      await bonding.setBondableValue(address, weight * weightDivisor)
      await pool.joinPool(address)
    }

    pool = await FullyBackedSortitionPool.new(bonding.address, bond, weightDivisor, owner)
  })

  describe('isOperatorInitialized', async () => {
    it('reverts if operator is not in the pool', async () => {
      expectRevert(
        pool.isOperatorInitialized(alice),
        'Operator is not in the pool',
      )
    })

    it('returns false when initialization period not passed', async () => {
      await prepareOperator(alice, 10)

      assert.isFalse(await pool.isOperatorInitialized(alice))

      assert.isFalse(
        await pool.isOperatorInitialized(alice),
        'incorrect result at the beginning of the period',
      )

      await mineBlocks((await pool.operatorInitBlocks()))

      assert.isFalse(
        await pool.isOperatorInitialized(alice),
        'incorrect result when period almost passed',
      )
    })

    it('returns true when initialization period passed', async () => {
      await prepareOperator(alice, 10)

      await mineBlocks((await pool.operatorInitBlocks()).addn(1))

      assert.isTrue(await pool.isOperatorInitialized(alice))
    })
  })

  describe('selectSetGroup', async () => {
    it('returns group of expected size with unique members', async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)
      await prepareOperator(carol, 12)
      await prepareOperator(david, 13)
      await prepareOperator(emily, 14)

      await mineBlocks(11)

      let group

      group = await pool.selectSetGroup.call(3, seed, bond, { from: owner })
      await pool.selectSetGroup(3, seed, bond, { from: owner })
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      group = await pool.selectSetGroup.call(5, seed, bond, { from: owner })
      await pool.selectSetGroup(5, seed, bond, { from: owner })
      assert.equal(group.length, 5)
      assert.isFalse(hasDuplicates(group))
    })

    it('updates operators\' weight', async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)
      await prepareOperator(carol, 12)

      await mineBlocks(11)

      const preWeight = await pool.getPoolWeight(alice)
      assert.equal(preWeight, 10)

      await pool.selectSetGroup(3, seed, bond, { from: owner })

      const postWeight = await pool.getPoolWeight(alice)
      assert.equal(postWeight, 8)
    })

    function hasDuplicates(array) {
      return (new Set(array)).size !== array.length
    }

    it('reverts when called by non-owner', async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)
      await prepareOperator(carol, 12)

      await mineBlocks(11)

      try {
        await pool.selectSetGroup(3, seed, bond, { from: alice })
      } catch (error) {
        assert.include(error.message, 'Only owner may select groups')
        return
      }

      assert.fail('Expected throw not received')
    })

    it('reverts when there are no operators in pool', async () => {
      try {
        await pool.selectSetGroup(3, seed, bond, { from: owner })
      } catch (error) {
        assert.include(error.message, 'Not enough operators in pool')
        return
      }

      assert.fail('Expected throw not received')
    })

    it('reverts when there are not enough operators in pool', async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)

      await mineBlocks(11)

      try {
        await pool.selectSetGroup(3, seed, bond, { from: owner })
      } catch (error) {
        assert.include(error.message, 'Not enough operators in pool')
        return
      }

      assert.fail('Expected throw not received')
    })

    it('removes ineligible operators and still works afterwards', async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)
      await prepareOperator(carol, 12)
      await prepareOperator(david, 5)

      await mineBlocks(11)

      await bonding.setBondableValue(carol, 1 * weightDivisor)

      try {
        await pool.selectSetGroup(4, seed, bond, { from: owner })
      } catch (error) {
        assert.include(error.message, 'Not enough operators in pool')

        group = await pool.selectSetGroup.call(3, seed, bond, { from: owner })

        assert.equal(group.length, 3)
        assert.isFalse(hasDuplicates(group))

        return
      }

      assert.fail('Expected throw not received')
    })

    it('updates operators whose weight has increased', async () => {
      await prepareOperator(alice, 10)
      await prepareOperator(bob, 11)
      await prepareOperator(carol, 12)

      await mineBlocks(11)

      await bonding.setBondableValue(carol, 15 * weightDivisor)

      group = await pool.selectSetGroup.call(3, seed, bond, { from: owner })
      await pool.selectSetGroup(3, seed, bond, { from: owner })
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      const postWeight = await pool.getPoolWeight(carol)
      assert.equal(postWeight, 13)
    })
  })
})
