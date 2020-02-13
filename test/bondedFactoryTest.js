const BondedSortitionPoolFactory = artifacts.require('./contracts/BondedSortitionPoolFactory.sol')
const BondedSortitionPool = artifacts.require('./contracts/BondedSortitionPool.sol')
const StakingContractStub = artifacts.require('StakingContractStub.sol')
const BondingContractStub = artifacts.require('BondingContractStub.sol')

contract('BondedSortitionPoolFactory', (accounts) => {
  let bondedSortitionPoolFactory
  let stakingContract
  let bondingContract
  const minimumStake = 1
  const initialMinimumBond = 1
  const initBlocks = 10

  before(async () => {
    bondedSortitionPoolFactory = await BondedSortitionPoolFactory.deployed()
    stakingContract = await StakingContractStub.new()
    bondingContract = await BondingContractStub.new()
  })

  describe('createSortitionPool()', async () => {
    it('creates independent pools', async () => {
      const pool1Address = await bondedSortitionPoolFactory.createSortitionPool.call(
        stakingContract.address,
        bondingContract.address,
        minimumStake,
        initialMinimumBond,
        initBlocks,
      )
      await bondedSortitionPoolFactory.createSortitionPool(
        stakingContract.address,
        bondingContract.address,
        minimumStake,
        initialMinimumBond,
        initBlocks,
      )
      const pool1 = await BondedSortitionPool.at(pool1Address)

      const pool2Address = await bondedSortitionPoolFactory.createSortitionPool.call(
        stakingContract.address,
        bondingContract.address,
        minimumStake,
        initialMinimumBond,
        initBlocks,
      )
      await bondedSortitionPoolFactory.createSortitionPool(
        stakingContract.address,
        bondingContract.address,
        minimumStake,
        initialMinimumBond,
        initBlocks,
      )
      const pool2 = await BondedSortitionPool.at(pool2Address)

      assert.notEqual(pool1Address, pool2Address)

      stakingContract.setStake(accounts[1], 11)
      stakingContract.setStake(accounts[2], 12)
      bondingContract.setBondableValue(accounts[1], 11)
      bondingContract.setBondableValue(accounts[2], 12)

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
