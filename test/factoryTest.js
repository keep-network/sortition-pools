const { helpers, ethers } = require("hardhat")
const { expect } = require("chai")
const utils = require("./utils")

describe("SortitionPoolFactory", () => {
  const seed =
    "0xff39d6cca87853892d2854566e883008bc000000000000000000000000000000"
  const minStake = 2000
  const poolWeightDivisor = 2000
  let alice
  let aliceID
  let bob
  let bobID
  let staking
  let factory

  beforeEach(async () => {
    alice = await ethers.getSigner(0)
    bob = await ethers.getSigner(1)

    const StakingContractStub = await ethers.getContractFactory(
      "StakingContractStub",
    )
    staking = await StakingContractStub.deploy()
    await staking.deployed()

    const SortitionPoolFactory = await ethers.getContractFactory(
      "SortitionPoolFactory",
    )
    factory = await SortitionPoolFactory.deploy()
    await factory.deployed()
  })

  describe("createSortitionPool", () => {
    it("creates independent clones", async () => {
      const tx1 = await factory.createSortitionPool(
        staking.address,
        minStake,
        poolWeightDivisor,
      )
      const receipt1 = await tx1.wait()
      let events = utils.pastEvents(receipt1, factory, "SortitionPoolCreated")
      const sortitionPoolAddress1 = events[0].args["sortitionPoolAddress"]
      const sortitionPool1 = await ethers.getContractAt(
        "SortitionPool",
        sortitionPoolAddress1,
      )

      const tx2 = await factory.createSortitionPool(
        staking.address,
        minStake,
        poolWeightDivisor,
      )
      const receipt2 = await tx2.wait()
      events = utils.pastEvents(receipt2, factory, "SortitionPoolCreated")
      const sortitionPoolAddress2 = events[0].args["sortitionPoolAddress"]
      const sortitionPool2 = await ethers.getContractAt(
        "SortitionPool",
        sortitionPoolAddress2,
      )

      await staking.setStake(alice.address, 22000)
      await staking.setStake(bob.address, 24000)

      await sortitionPool1.insertOperator(alice.address)
      await sortitionPool2.insertOperator(bob.address)

      aliceID = await sortitionPool1.getOperatorID(alice.address)
      bobID = await sortitionPool2.getOperatorID(bob.address)

      await helpers.time.mineBlocks(11)

      const group1 = await sortitionPool1.selectGroup(2, seed)
      expect(group1).to.deep.equal([aliceID, aliceID])

      const group2 = await sortitionPool2.selectGroup(2, seed)
      expect(group2).to.deep.equal([bobID, bobID])
    })
  })
})
