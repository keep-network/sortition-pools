const SortitionPoolFactory = artifacts.require('./contracts/SortitionPoolFactory.sol')
const SortitionPool = artifacts.require('./contracts/SortitionPool.sol')
const StakingContractStub = artifacts.require('StakingContractStub.sol')

contract('SortitionPoolFactory', (accounts) => {
  const seed = '0xff39d6cca87853892d2854566e883008bc'
  const minStake = 2000
  let sortitionPoolFactory
  let staking

  before(async () => {
    staking = await StakingContractStub.new()
    sortitionPoolFactory = await SortitionPoolFactory.new()
  })

  describe('createSortitionPool()', async () => {
    it('creates independent clones', async () => {
      const sortitionPool1Address = await sortitionPoolFactory.createSortitionPool.call(staking.address, minStake)
      await sortitionPoolFactory.createSortitionPool(staking.address, minStake)
      const sortitionPool1 = await SortitionPool.at(sortitionPool1Address)

      const sortitionPool2Address = await sortitionPoolFactory.createSortitionPool.call(staking.address, minStake)
      await sortitionPoolFactory.createSortitionPool(staking.address, minStake)
      const sortitionPool2 = await SortitionPool.at(sortitionPool2Address)

      await sortitionPool1.insertOperator(accounts[1], 11)
      await sortitionPool2.insertOperator(accounts[2], 12)

      const group1 = await sortitionPool1.selectGroup(2, seed)
      assert.deepEqual(group1, [accounts[1], accounts[1]])

      const group2 = await sortitionPool2.selectGroup(2, seed)
      assert.deepEqual(group2, [accounts[2], accounts[2]])
    })
  })
})
