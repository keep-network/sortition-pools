const Branch = artifacts.require('Branch')
const Position = artifacts.require('Position')
const StackLib = artifacts.require('StackLib')
const Trunk = artifacts.require('Trunk')
const Leaf = artifacts.require('Leaf')
const SortitionPool = artifacts.require('./contracts/SortitionPool.sol')
const StakingContractStub = artifacts.require('StakingContractStub.sol')

contract('SortitionPool', (accounts) => {
  const seed = '0xff39d6cca87853892d2854566e883008bc'
  const minStake = 2000
  let staking
  let pool
  const alice = accounts[0]
  const bob = accounts[1]
  const carol = accounts[2]
  const david = accounts[3]

  beforeEach(async () => {
    SortitionPool.link(Branch)
    SortitionPool.link(Position)
    SortitionPool.link(StackLib)
    SortitionPool.link(Trunk)
    SortitionPool.link(Leaf)
    staking = await StakingContractStub.new()
    pool = await SortitionPool.new(staking.address, minStake)
    await pool.reseed(seed)
  })

  describe('selectGroup', async () => {
    it('returns group of expected size', async () => {
      await staking.setStake(alice, 20000)
      await staking.setStake(bob, 22000)
      await staking.setStake(carol, 24000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)
      await pool.joinPool(carol)

      const group = await pool.selectGroup.call(3)
      await pool.selectGroup(3)

      assert.equal(group.length, 3)
    })

    it('reverts when there are no operators in pool', async () => {
      try {
        await pool.selectGroup.call(3)
      } catch (error) {
        assert.include(error.message, 'No operators in pool')
        return
      }

      assert.fail('Expected throw not received')
    })

    it('returns group of expected size if less operators are registered', async () => {
      await staking.setStake(alice, 2000)
      await pool.joinPool(alice)

      const group = await pool.selectGroup.call(5)
      await pool.selectGroup(5)
      assert.equal(group.length, 5)
    })

    it('removes ineligible operators', async () => {
      await staking.setStake(alice, 2000)
      await staking.setStake(bob, 4000000)
      await pool.joinPool(alice)
      await pool.joinPool(bob)

      await staking.setStake(bob, 1000)

      const group = await pool.selectGroup.call(5)
      await pool.selectGroup(5)
      assert.deepEqual(group, [alice, alice, alice, alice, alice])
    })
  })
})
