const Branch = artifacts.require('Branch')
const Position = artifacts.require('Position')
const StackLib = artifacts.require('StackLib')
const Trunk = artifacts.require('Trunk')
const Leaf = artifacts.require('Leaf')
const SortitionPool = artifacts.require('./contracts/SortitionPool.sol')
const StakingContractStub = artifacts.require('StakingContractStub.sol')

const { tokens } = require('./token')

contract('SortitionPool', (accounts) => {
  const seed = '0xff39d6cca87853892d2854566e883008bc'
  const minStake = tokens(2000)
  let staking
  let pool
  const alice = accounts[0]
  const bob = accounts[1]
  const carol = accounts[2]

  beforeEach(async () => {
    SortitionPool.link(Branch)
    SortitionPool.link(Position)
    SortitionPool.link(StackLib)
    SortitionPool.link(Trunk)
    SortitionPool.link(Leaf)
    staking = await StakingContractStub.new()
    pool = await SortitionPool.new(staking.address, minStake, accounts[9])
  })

  describe('constructor', async () => {
    it('enforces adequate minimum stake', async () => {
      try {
        await SortitionPool.new(staking.address, tokens(1795), accounts[9])
      } catch (error) {
        assert.include(error.message, 'Insufficient minimum stake')
        return
      }

      assert.fail('Expected throw not received')
    })
  })

  describe('joinPool', async () => {
    it('accepts eligible operators', async () => {
      await staking.setStake(alice, tokens(4000))
      await pool.joinPool(alice)

      const aliceInPool = await pool.isOperatorInPool(alice)
      assert.isTrue(aliceInPool)
    })

    it('rejects ineligible operators', async () => {
      await staking.setStake(bob, tokens(1000))

      try {
        await pool.joinPool(bob)
      } catch (error) {
        assert.include(error.message, 'Operator not eligible')
        return
      }

      assert.fail('Expected throw not received')
    })

    it('rejects operators with overflowing weight', async () => {
      await staking.setStake(carol, minStake.muln(2**16))

      try {
        await pool.joinPool(carol)
      } catch (error) {
        assert.include(
          error.message,
          'Operator weights above 65535 are not supported')
        return
      }

      assert.fail('Expected throw not received')
    })
  })

  describe('selectGroup', async () => {
    it('returns group of expected size', async () => {
      await staking.setStake(alice, tokens(20000))
      await staking.setStake(bob, tokens(22000))
      await staking.setStake(carol, tokens(24000))
      await pool.joinPool(alice)
      await pool.joinPool(bob)
      await pool.joinPool(carol)

      const group = await pool.selectGroup.call(3, seed)
      await pool.selectGroup(3, seed)

      assert.equal(group.length, 3)
    })

    it('reverts when there are no operators in pool', async () => {
      try {
        await pool.selectGroup.call(3, seed)
      } catch (error) {
        assert.include(error.message, 'No operators in pool')
        return
      }

      assert.fail('Expected throw not received')
    })

    it('returns group of expected size if less operators are registered', async () => {
      await staking.setStake(alice, tokens(2000))
      await pool.joinPool(alice)

      const group = await pool.selectGroup.call(5, seed)
      await pool.selectGroup(5, seed)
      assert.equal(group.length, 5)
    })

    it('removes ineligible operators', async () => {
      await staking.setStake(alice, tokens(2000))
      await staking.setStake(bob, tokens(4000000))
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, tokens(1000))

      const group = await pool.selectGroup.call(5, seed)
      await pool.selectGroup(5, seed)
      assert.deepEqual(group, [alice, alice, alice, alice, alice])
    })

    it('removes outdated but still operators', async () => {
      await staking.setStake(alice, tokens(2000))
      await staking.setStake(bob, tokens(4000000))
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, tokens(390000))

      const group = await pool.selectGroup.call(5, seed)
      await pool.selectGroup(5, seed)
      assert.deepEqual(group, [alice, alice, alice, alice, alice])
    })

    it('lets outdated operators update their status', async () => {
      await staking.setStake(alice, tokens(2000))
      await staking.setStake(bob, tokens(4000000))
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, tokens(390000))
      await staking.setStake(alice, tokens(1000))

      await pool.updateOperatorStatus(bob)
      await pool.updateOperatorStatus(alice)

      const group = await pool.selectGroup.call(5, seed)
      await pool.selectGroup(5, seed)
      assert.deepEqual(group, [bob, bob, bob, bob, bob])
    })

    it('can select really large groups efficiently', async () => {
      for (i = 0; i < 9; i++) {
        await staking.setStake(accounts[i], minStake.muln(i + 10))
        await pool.joinPool(accounts[i])
      }

      const group = await pool.selectGroup.call(100, seed)
      await pool.selectGroup(100, seed)
      assert.equal(group.length, 100)
    })
  })
})
