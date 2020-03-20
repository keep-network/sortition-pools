const FullyBackedSortitionPoolFactory = artifacts.require('./contracts/FullyBackedSortitionPoolFactory.sol')
const FullyBackedSortitionPool = artifacts.require('./contracts/FullyBackedSortitionPool.sol')
const BondingContractStub = artifacts.require('BondingContractStub.sol')

contract('FullyBackedSortitionPoolFactory', (accounts) => {
  let bondingContract
  let factory

  const minimumStake = 10
  const bondWeightDivisor = 5

  before(async () => {
    factory = await FullyBackedSortitionPoolFactory.deployed()
    bondingContract = await BondingContractStub.new()
  })

  describe('createSortitionPool()', async () => {
    it('creates independent pools', async () => {
      const pool1Address = await factory.createSortitionPool.call(
        bondingContract.address,
        minimumStake,
        bondWeightDivisor,
      )
      await factory.createSortitionPool(
        bondingContract.address,
        minimumStake,
        bondWeightDivisor,
      )
      const pool1 = await FullyBackedSortitionPool.at(pool1Address)

      const pool2Address = await factory.createSortitionPool.call(
        bondingContract.address,
        minimumStake,
        bondWeightDivisor,
      )
      await factory.createSortitionPool(
        bondingContract.address,
        minimumStake,
        bondWeightDivisor,
      )
      const pool2 = await FullyBackedSortitionPool.at(pool2Address)

      assert.notEqual(pool1Address, pool2Address)

      bondingContract.setBondableValue(accounts[1], 100)
      bondingContract.setBondableValue(accounts[2], 200)

      assert.equal(await pool1.operatorsInPool(), 0)
      assert.equal(await pool2.operatorsInPool(), 0)

      await pool1.joinPool(accounts[1])
      assert.equal(await pool1.operatorsInPool(), 1)
      assert.equal(await pool2.operatorsInPool(), 0)

      await pool2.joinPool(accounts[2])
      assert.equal(await pool1.operatorsInPool(), 1)
      assert.equal(await pool2.operatorsInPool(), 1)
    })
  })
})
