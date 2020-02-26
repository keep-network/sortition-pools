const Branch = artifacts.require('Branch')
const Position = artifacts.require('Position')
const StackLib = artifacts.require('StackLib')
const Leaf = artifacts.require('Leaf')
const FullyBackedSortitionPool = artifacts.require('./contracts/FullyBackedSortitionPool.sol')

const BondingContractStub = artifacts.require('BondingContractStub.sol')

const { mineBlocks } = require('./mineBlocks')

const { expectRevert } = require('@openzeppelin/test-helpers')

contract('FullyBackedSortitionPool', (accounts) => {
  // const seed = '0xff39d6cca87853892d2854566e883008bc'
  const bond = 2000
  const weightDivisor = 1000
  const alice = accounts[0]
  const owner = accounts[9]
  let pool
  let bonding
  let prepareOperator

  beforeEach(async () => {
    FullyBackedSortitionPool.link(Branch)
    FullyBackedSortitionPool.link(Position)
    FullyBackedSortitionPool.link(StackLib)
    FullyBackedSortitionPool.link(Leaf)
    bonding = await BondingContractStub.new()

    prepareOperator = async (address, weight) => {
      await bonding.setBondableValue(address, weight * weightDivisor)
      await pool.joinPool(address)
    }

    pool = await FullyBackedSortitionPool.new(bonding.address, bond, weightDivisor, owner)
  })

  describe('isOperatorInitialized', async () => {
    it('reverts if operator is not in the pool', async () => {
      expectRevert(
        pool.isOperatorInitialized(alice),
        'Operator is not in the pool',
      )
    })

    it('returns false when initialization period not passed', async () => {
      await prepareOperator(alice, 10)

      assert.isFalse(await pool.isOperatorInitialized(alice))

      assert.isFalse(
        await pool.isOperatorInitialized(alice),
        'incorrect result at the beginning of the period',
      )

      await mineBlocks((await pool.operatorInitBlocks()))

      assert.isFalse(
        await pool.isOperatorInitialized(alice),
        'incorrect result when period almost passed',
      )
    })

    it('returns true when initialization period passed', async () => {
      await prepareOperator(alice, 10)

      await mineBlocks((await pool.operatorInitBlocks()).addn(1))

      assert.isTrue(await pool.isOperatorInitialized(alice))
    })
  })
})
