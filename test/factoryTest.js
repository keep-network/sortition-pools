const SortitionPoolFactory = artifacts.require(
  "./contracts/SortitionPoolFactory.sol"
)
const SortitionPool = artifacts.require("./contracts/SortitionPool.sol")
const StakingContractStub = artifacts.require("StakingContractStub.sol")

const { mineBlocks } = require("./mineBlocks")

contract("SortitionPoolFactory", (accounts) => {
  const seed = "0xff39d6cca87853892d2854566e883008bc"
  const minStake = 2000
  const poolWeightDivisor = 2000
  let factory
  let staking
  const alice = accounts[0]
  const bob = accounts[1]

  before(async () => {
    staking = await StakingContractStub.new()
    factory = await SortitionPoolFactory.new()
  })

  describe("createSortitionPool()", async () => {
    it("creates independent clones", async () => {
      const sortitionPool1Address = await factory.createSortitionPool.call(
        staking.address,
        minStake,
        poolWeightDivisor
      )
      await factory.createSortitionPool(
        staking.address,
        minStake,
        poolWeightDivisor
      )
      const sortitionPool1 = await SortitionPool.at(sortitionPool1Address)

      const sortitionPool2Address = await factory.createSortitionPool.call(
        staking.address,
        minStake,
        poolWeightDivisor
      )
      await factory.createSortitionPool(
        staking.address,
        minStake,
        poolWeightDivisor
      )
      const sortitionPool2 = await SortitionPool.at(sortitionPool2Address)

      await staking.setStake(alice, 22000)
      await staking.setStake(bob, 24000)

      await sortitionPool1.joinPool(alice)
      await sortitionPool2.joinPool(bob)

      await mineBlocks(11)

      const group1 = await sortitionPool1.selectGroup.call(2, seed)
      assert.deepEqual(group1, [alice, alice])

      const group2 = await sortitionPool2.selectGroup.call(2, seed)
      assert.deepEqual(group2, [bob, bob])
    })
  })
})
