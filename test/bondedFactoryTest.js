const {accounts, contract} = require("@openzeppelin/test-environment")

const BondedSortitionPoolFactory = contract.fromArtifact(
  "BondedSortitionPoolFactory",
)
const BondedSortitionPool = contract.fromArtifact("BondedSortitionPool")
const StakingContractStub = contract.fromArtifact("StakingContractStub")
const BondingContractStub = contract.fromArtifact("BondingContractStub")
const StackLib = contract.fromArtifact("StackLib")

const chai = require("chai")
const assert = chai.assert

describe("BondedSortitionPoolFactory", () => {
  let bondedSortitionPoolFactory
  let stakingContract
  let bondingContract
  const minimumStake = 1
  const initialMinimumBond = 1
  const poolWeightDivisor = 1

  before(async () => {
    await BondedSortitionPoolFactory.detectNetwork()
    await BondedSortitionPoolFactory.link(
      "StackLib",
      (await StackLib.new()).address,
    )

    bondedSortitionPoolFactory = await BondedSortitionPoolFactory.new()
    stakingContract = await StakingContractStub.new()
    bondingContract = await BondingContractStub.new()
  })

  describe("createSortitionPool()", async () => {
    it("creates independent pools", async () => {
      const pool1Address = await bondedSortitionPoolFactory.createSortitionPool.call(
        stakingContract.address,
        bondingContract.address,
        minimumStake,
        initialMinimumBond,
        poolWeightDivisor,
      )
      await bondedSortitionPoolFactory.createSortitionPool(
        stakingContract.address,
        bondingContract.address,
        minimumStake,
        initialMinimumBond,
        poolWeightDivisor,
      )
      const pool1 = await BondedSortitionPool.at(pool1Address)

      const pool2Address = await bondedSortitionPoolFactory.createSortitionPool.call(
        stakingContract.address,
        bondingContract.address,
        minimumStake,
        initialMinimumBond,
        poolWeightDivisor,
      )
      await bondedSortitionPoolFactory.createSortitionPool(
        stakingContract.address,
        bondingContract.address,
        minimumStake,
        initialMinimumBond,
        poolWeightDivisor,
      )
      const pool2 = await BondedSortitionPool.at(pool2Address)

      assert.notEqual(pool1Address, pool2Address)

      await stakingContract.setStake(accounts[1], 11)
      await stakingContract.setStake(accounts[2], 12)
      await bondingContract.setBondableValue(accounts[1], 11)
      await bondingContract.setBondableValue(accounts[2], 12)

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
