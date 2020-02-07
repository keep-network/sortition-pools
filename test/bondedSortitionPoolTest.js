const Branch = artifacts.require('Branch')
const Position = artifacts.require('Position')
const StackLib = artifacts.require('StackLib')
const Trunk = artifacts.require('Trunk')
const Leaf = artifacts.require('Leaf')
const BondedSortitionPool = artifacts.require('./contracts/BondedSortitionPool.sol')

const StakingContractStub = artifacts.require('StakingContractStub.sol')
const BondingContractStub = artifacts.require('BondingContractStub.sol')

contract('BondedSortitionPool', (accounts) => {
  const seed = '0xff39d6cca87853892d2854566e883008bc'
  const bond = 100000000
  const minStake = 2000
  let pool
  let bonding
  let staking
  let prepareOperator

  beforeEach(async () => {
    BondedSortitionPool.link(Branch)
    BondedSortitionPool.link(Position)
    BondedSortitionPool.link(StackLib)
    BondedSortitionPool.link(Trunk)
    BondedSortitionPool.link(Leaf)
    staking = await StakingContractStub.new()
    bonding = await BondingContractStub.new()
    prepareOperator = async (address, weight) => {
      await pool.insertOperator(address, weight)
      await bonding.setBondableValue(address, weight * bond)
    }
    pool = await BondedSortitionPool.new(staking.address, bonding.address, minStake, bond, accounts[9])
  })

  describe('selectSetGroup', async () => {
    it('returns group of expected size with unique members', async () => {
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 11)
      await prepareOperator(accounts[2], 12)
      await prepareOperator(accounts[3], 5)
      await prepareOperator(accounts[4], 1)

      let group

      group = await pool.selectSetGroup.call(3, seed, bond)
      await pool.selectSetGroup(3, seed, bond)
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      group = await pool.selectSetGroup.call(5, seed, bond)
      assert.equal(group.length, 5)
      assert.isFalse(hasDuplicates(group))
    })

    function hasDuplicates(array) {
      return (new Set(array)).size !== array.length
    }

    it('reverts when there are no operators in pool', async () => {
      try {
        await pool.selectSetGroup(3, seed, bond)
      } catch (error) {
        assert.include(error.message, 'Not enough operators in pool')
        return
      }

      assert.fail('Expected throw not received')
    })

    it('reverts when there are not enough operators in pool', async () => {
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 11)

      try {
        await pool.selectSetGroup(3, seed, bond)
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

      await bonding.setBondableValue(accounts[2], 1 * bond)

      try {
        await pool.selectSetGroup(4, seed, bond)
      } catch (error) {
        assert.include(error.message, 'Not enough operators in pool')

        group = await pool.selectSetGroup.call(3, seed, bond)

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

      await bonding.setBondableValue(accounts[2], 15 * bond)

      group = await pool.selectSetGroup.call(3, seed, bond)
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

      await bonding.setBondableValue(accounts[0], 1 * bond)
      await bonding.setBondableValue(accounts[1], 1 * bond)
      await bonding.setBondableValue(accounts[2], 1 * bond)
      await bonding.setBondableValue(accounts[4], 1 * bond)
      await bonding.setBondableValue(accounts[6], 7 * bond)
      await bonding.setBondableValue(accounts[7], 1 * bond)
      await bonding.setBondableValue(accounts[9], 1 * bond)

      group = await pool.selectSetGroup.call(3, seed, bond)
      await pool.selectSetGroup(3, seed, bond)
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      try {
        await pool.selectSetGroup(4, seed, bond)
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

      group = await pool.selectSetGroup.call(3, seed, bond)
      await pool.selectSetGroup(3, seed, bond)
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))
    })
  })
})
