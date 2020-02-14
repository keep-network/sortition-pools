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
const SortitionPool = artifacts.require('./contracts/SortitionPool.sol')
const StakingContractStub = artifacts.require('StakingContractStub.sol')

async function mine(blocks) {
  for (i = 0; i < blocks; i++) {
    await time.advanceBlock()
  }
}

contract('SortitionPool', (accounts) => {
  const seed = '0xff39d6cca87853892d2854566e883008bc'
  const minStake = 2000
  const initBlocks = 10
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
      owner,
      initBlocks,
    )
  })

  describe('selectGroup', async () => {
    it('returns group of expected size', async () => {
      await staking.setStake(alice, 20000)
      await staking.setStake(bob, 22000)
      await staking.setStake(carol, 24000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)
      await pool.joinPool(carol)

      await mine(11)

      const group = await pool.selectGroup.call(3, seed, { from: owner })
      await pool.selectGroup(3, seed, { from: owner })

      assert.equal(group.length, 3)
    })

    it('only serves its owner', async () => {
      await staking.setStake(alice, 20000)
      await pool.joinPool(alice)

      await mine(11)
      try {
        await pool.selectGroup.call(1, seed, { from: bob })
      } catch (error) {
        assert.include(error.message, 'Only owner may select groups')
        return
      }

      assert.fail('Expected throw not received')
    })

    it('reverts when there are no operators in pool', async () => {
      try {
        await pool.selectGroup.call(3, seed, { from: owner })
      } catch (error) {
        assert.include(error.message, 'No operators in pool')
        return
      }

      assert.fail('Expected throw not received')
    })

    it('returns group of expected size if less operators are registered', async () => {
      await staking.setStake(alice, 2000)
      await pool.joinPool(alice)

      await mine(11)

      const group = await pool.selectGroup.call(5, seed, { from: owner })
      await pool.selectGroup(5, seed, { from: owner })
      assert.equal(group.length, 5)
    })

    it('removes ineligible operators', async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 4000000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, 1000)

      await mine(11)

      const group = await pool.selectGroup.call(5, seed, { from: owner })
      await pool.selectGroup(5, seed, { from: owner })
      assert.deepEqual(group, [alice, alice, alice, alice, alice])
    })

    it('removes outdated but still operators', async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 4000000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, 390000)

      await mine(11)

      const group = await pool.selectGroup.call(5, seed, { from: owner })
      await pool.selectGroup(5, seed, { from: owner })
      assert.deepEqual(group, [alice, alice, alice, alice, alice])
    })

    it('lets outdated operators update their status', async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 4000000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, 390000)
      await staking.setStake(alice, 1000)

      await mine(11)

      await pool.updateOperatorStatus(bob)
      await pool.updateOperatorStatus(alice)

      const group = await pool.selectGroup.call(5, seed, { from: owner })
      await pool.selectGroup(5, seed, { from: owner })
      assert.deepEqual(group, [bob, bob, bob, bob, bob])
    })

    it('ignores too recently added operators', async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 2000)
      await pool.joinPool(alice)

      await mine(11)

      await pool.joinPool(bob)

      const group = await pool.selectGroup.call(5, seed, { from: owner })
      await pool.selectGroup(5, seed, { from: owner })
      assert.deepEqual(group, [alice, alice, alice, alice, alice])

      await mine(11)
      await staking.setStake(alice, 1000)

      const group2 = await pool.selectGroup.call(5, seed, { from: owner })
      assert.deepEqual(group2, [bob, bob, bob, bob, bob])
    })

    it('can select really large groups efficiently', async () => {
      for (i = 101; i < 150; i++) {
        const address = '0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' + i.toString()
        await staking.setStake(address, minStake * i)
        await pool.joinPool(address)
      }

      await mine(11)

      const group = await pool.selectGroup.call(100, seed, { from: owner })
      await pool.selectGroup(100, seed, { from: owner })
      assert.equal(group.length, 100)
    })
  })
})
