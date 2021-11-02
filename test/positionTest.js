const { expect } = require("chai")
const utils = require("./utils")
const params = require("./params")

describe("Position", async () => {
  let positionInstance
  let childPosition
  let parentPosition
  let fullPosition

  beforeEach(async () => {
    const PositionStub = await ethers.getContractFactory("PositionStub")
    positionInstance = await PositionStub.deploy()
    await positionInstance.deployed()

    fullPosition = utils
      .range(params.levels)
      .map((n) => (n + 1) % params.slotCount << (n * params.slotBits))
      .reduce(utils.sumReducer)
    childPosition = 1
    parentPosition = utils
      .range(params.levels - 1)
      .map((n) => (n + 2) % params.slotCount << (n * params.slotBits))
      .reduce(utils.sumReducer)
  })

  describe("slot", async () => {
    it("Returns the last bits", async () => {
      const result = await positionInstance.slot(fullPosition)
      expect(result).to.be.equal(childPosition)
    })
  })

  describe("parent", async () => {
    it("Returns the first bits", async () => {
      const result = await positionInstance.parent(fullPosition)
      expect(result).to.be.equal(parentPosition)
    })
  })

  describe("child", async () => {
    it("Returns the child address", async () => {
      const result = await positionInstance.child(parentPosition, childPosition)
      expect(result).to.be.equal(fullPosition)
    })
  })
})
