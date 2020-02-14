require('@openzeppelin/test-helpers/configure')({
  singletons: {
    defaultGas: 6e6,
  },
})
const { time } = require('@openzeppelin/test-helpers')

const Branch = artifacts.require('Branch')
const Position = artifacts.require('Position')
const StackLib = artifacts.require('StackLib')
const Leaf = artifacts.require('Leaf')
const BondedSortitionPool = artifacts.require('./contracts/BondedSortitionPool.sol')

const StakingContractStub = artifacts.require('StakingContractStub.sol')
const BondingContractStub = artifacts.require('BondingContractStub.sol')

async function mine(blocks) {
  for (i = 0; i < blocks; i++) {
    await time.advanceBlock()
  }
}

contract('BondedSortitionPool', (accounts) => {
  const seed = '0xff39d6cca87853892d2854566e883008bc'
  const bond = 100000000
  const minStake = 2000
  const initBlocks = 10
  const owner = accounts[9]
  let pool
  let bonding
  let staking
  let prepareOperator

  beforeEach(async () => {
    BondedSortitionPool.link(Branch)
    BondedSortitionPool.link(Position)
    BondedSortitionPool.link(StackLib)
    BondedSortitionPool.link(Leaf)
    staking = await StakingContractStub.new()
    bonding = await BondingContractStub.new()

    prepareOperator = async (address, weight) => {
      await bonding.setBondableValue(address, weight * bond, { from: owner })
      await staking.setStake(address, weight * minStake)
      await pool.joinPool(address)
    }

    pool = await BondedSortitionPool.new(
      staking.address,
      bonding.address,
      minStake,
      bond,
      owner,
      initBlocks,
    )
  })

  describe('selectSetGroup', async () => {
    it('returns group of expected size with unique members', async () => {
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 11)
      await prepareOperator(accounts[2], 12)
      await prepareOperator(accounts[3], 5)
      await prepareOperator(accounts[4], 1)

      await mine(11)

      let group

      group = await pool.selectSetGroup.call(3, seed, bond, { from: owner })
      await pool.selectSetGroup(3, seed, bond, { from: owner })
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      group = await pool.selectSetGroup.call(5, seed, bond, { from: owner })
      assert.equal(group.length, 5)
      assert.isFalse(hasDuplicates(group))
    })

    it('only serves its owner', async () => {
      await prepareOperator(accounts[0], 10)

      await mine(11)

      try {
        await pool.selectGroup.call(1, seed, { from: accounts[1] })
      } catch (error) {
        assert.include(error.message, 'Only owner may select groups')
        return
      }

      assert.fail('Expected throw not received')
    })

    function hasDuplicates(array) {
      return (new Set(array)).size !== array.length
    }

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
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 11)

      await mine(11)

      try {
        await pool.selectSetGroup(3, seed, bond, { from: owner })
      } catch (error) {
        assert.include(error.message, 'Not enough operators in pool')
        return
      }

      assert.fail('Expected throw not received')
    })

    it('removes ineligible operators and still works afterwards', async () => {
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 11)
      await prepareOperator(accounts[2], 12)
      await prepareOperator(accounts[3], 5)

      await mine(11)

      await staking.setStake(accounts[2], 1 * minStake)

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

    it('doesn\'t mind operators whose weight has increased', async () => {
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 11)
      await prepareOperator(accounts[2], 12)

      await mine(11)

      await staking.setStake(accounts[2], 15 * minStake)

      group = await pool.selectSetGroup.call(3, seed, bond, { from: owner })
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))
    })

    it('can handle removing multiple outdated operators', async () => {
      await prepareOperator(accounts[0], 70)
      await prepareOperator(accounts[1], 11)
      await prepareOperator(accounts[2], 12)
      await prepareOperator(accounts[3], 5)
      await prepareOperator(accounts[4], 2)
      await prepareOperator(accounts[5], 1)
      await prepareOperator(accounts[6], 8)
      await prepareOperator(accounts[7], 50)
      await prepareOperator(accounts[8], 3)
      await prepareOperator(accounts[9], 42)

      await mine(11)

      await staking.setStake(accounts[0], 1 * minStake)
      await staking.setStake(accounts[1], 1 * minStake)
      await staking.setStake(accounts[2], 1 * minStake)
      await staking.setStake(accounts[4], 1 * minStake)
      await staking.setStake(accounts[6], 7 * minStake)
      await staking.setStake(accounts[7], 1 * minStake)
      await staking.setStake(accounts[9], 1 * minStake)

      group = await pool.selectSetGroup.call(3, seed, bond, { from: owner })
      await pool.selectSetGroup(3, seed, bond, { from: owner })
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      try {
        await pool.selectSetGroup(4, seed, bond, { from: owner })
      } catch (error) {
        assert.include(error.message, 'Not enough operators in pool')
        return
      }

      assert.fail('Expected throw not received')
    })

    it('behaves reasonably with loads of operators', async () => {
      await prepareOperator(accounts[0], 1)
      await prepareOperator(accounts[1], 1)
      await prepareOperator(accounts[2], 1)
      await prepareOperator(accounts[3], 1)
      await prepareOperator(accounts[4], 1)
      await prepareOperator(accounts[5], 1)
      await prepareOperator(accounts[6], 1)
      await prepareOperator(accounts[7], 1)
      await prepareOperator(accounts[8], 1)
      await prepareOperator(accounts[9], 1)

      await mine(11)

      group = await pool.selectSetGroup.call(3, seed, bond, { from: owner })
      await pool.selectSetGroup(3, seed, bond, { from: owner })
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))
    })

    it('updates the bond value', async () => {
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 21)
      await prepareOperator(accounts[2], 32)

      await mine(11)

      group = await pool.selectSetGroup.call(3, seed, bond * 10, { from: owner })
      await pool.selectSetGroup(3, seed, bond * 10, { from: owner })
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      group = await pool.selectSetGroup.call(2, seed, bond * 20, { from: owner })
      await pool.selectSetGroup(2, seed, bond * 20, { from: owner })
      assert.equal(group.length, 2)
      assert.isFalse(hasDuplicates(group))

      try {
        await pool.selectSetGroup(3, seed, bond * 20, { from: owner })
      } catch (error) {
        assert.include(error.message, 'Not enough operators in pool')
        return
      }

      assert.fail('Expected throw not received')
    })
  })
})
