const BondedSortitionPoolFactory = artifacts.require('./contracts/BondedSortitionPoolFactory.sol')
const BondedSortitionPool = artifacts.require('./contracts/BondedSortitionPool.sol')

contract('BondedSortitionPoolFactory', (accounts) => {
  let bondedSortitionPoolFactory

  before(async () => {
    bondedSortitionPoolFactory = await BondedSortitionPoolFactory.deployed()
  })

  describe('createSortitionPool()', async () => {
    it('creates independent pools', async () => {
      const pool1Address = await bondedSortitionPoolFactory.createSortitionPool.call()
      await bondedSortitionPoolFactory.createSortitionPool()
      const pool1 = await BondedSortitionPool.at(pool1Address)

      const pool2Address = await bondedSortitionPoolFactory.createSortitionPool.call()
      await bondedSortitionPoolFactory.createSortitionPool()
      const pool2 = await BondedSortitionPool.at(pool2Address)

      assert.notEqual(pool1Address, pool2Address)

      assert.equal(await pool1.operatorsInPool(), 0)
      assert.equal(await pool2.operatorsInPool(), 0)

      await pool1.insertOperator(accounts[1], 11)
      assert.equal(await pool1.operatorsInPool(), 1)
      assert.equal(await pool2.operatorsInPool(), 0)

      await pool2.insertOperator(accounts[2], 12)
      assert.equal(await pool1.operatorsInPool(), 1)
      assert.equal(await pool2.operatorsInPool(), 1)
    })
  })
})
