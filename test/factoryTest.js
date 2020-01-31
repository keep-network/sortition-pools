const SortitionPoolFactory = artifacts.require('./contracts/SortitionPoolFactory.sol')
const SortitionPool = artifacts.require('./contracts/SortitionPool.sol')
const StakingContractStub = artifacts.require('StakingContractStub.sol')

contract('SortitionPoolFactory', (accounts) => {
  const seed = '0xff39d6cca87853892d2854566e883008bc'
  const minStake = 2000
  let sortitionPoolFactory
  let staking
  const alice = accounts[0]
  const bob = accounts[1]

  before(async () => {
    staking = await StakingContractStub.new()
    sortitionPoolFactory = await SortitionPoolFactory.deployed()
    await sortitionPoolFactory.setParams(staking.address, minStake)
  })

  describe('createSortitionPool()', async () => {
    it('creates independent clones', async () => {
      const sortitionPool1Address = await sortitionPoolFactory.createSortitionPool.call()
      await sortitionPoolFactory.createSortitionPool()
      const sortitionPool1 = await SortitionPool.at(sortitionPool1Address)

      const sortitionPool2Address = await sortitionPoolFactory.createSortitionPool.call()
      await sortitionPoolFactory.createSortitionPool()
      const sortitionPool2 = await SortitionPool.at(sortitionPool2Address)

      await staking.setStake(alice, 22000)
      await staking.setStake(bob, 24000)

      await sortitionPool1.joinPool(alice)
      await sortitionPool2.joinPool(bob)

      await sortitionPool1.reseed(seed)
      await sortitionPool2.reseed(seed)

      const group1 = await sortitionPool1.selectGroup.call(2)
      assert.deepEqual(group1, [alice, alice])

      const group2 = await sortitionPool2.selectGroup.call(2)
      assert.deepEqual(group2, [bob, bob])
    })
  })
})
