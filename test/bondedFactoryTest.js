const BondedSortitionPoolFactory = artifacts.require('./contracts/BondedSortitionPoolFactory.sol')
const BondedSortitionPool = artifacts.require('./contracts/BondedSortitionPool.sol')

contract('BondedSortitionPoolFactory', (accounts) => {
  let bondedSortitionPoolFactory
  const stakingContract = '0x0000000000000000000000000000000000000001'
  const bondingContract = '0x0000000000000000000000000000000000000002'
  const minimumStake = 1
  const initialMinimumBond = 1

  before(async () => {
    bondedSortitionPoolFactory = await BondedSortitionPoolFactory.deployed()
  })

  describe('createSortitionPool()', async () => {
    it('creates independent pools', async () => {
      const pool1Address = await bondedSortitionPoolFactory.createSortitionPool.call(
        stakingContract,
        bondingContract,
        minimumStake,
        initialMinimumBond,
      )
      await bondedSortitionPoolFactory.createSortitionPool(
        stakingContract,
        bondingContract,
        minimumStake,
        initialMinimumBond,
      )
      const pool1 = await BondedSortitionPool.at(pool1Address)

      const pool2Address = await bondedSortitionPoolFactory.createSortitionPool.call(
        stakingContract,
        bondingContract,
        minimumStake,
        initialMinimumBond,
      )
      await bondedSortitionPoolFactory.createSortitionPool(
        stakingContract,
        bondingContract,
        minimumStake,
        initialMinimumBond,
      )
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
