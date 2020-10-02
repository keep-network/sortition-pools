const {contract} = require("@openzeppelin/test-environment")

const Position = contract.fromArtifact("Position")
const PositionStub = contract.fromArtifact("PositionStub")
const utils = require("./helpers/utils")
const params = require("./helpers/params")

const DEPLOY = [
  {name: "Position", contract: Position},
  {name: "PositionStub", contract: PositionStub},
]

const chai = require("chai")
const assert = chai.assert

describe("Position", () => {
  let positionInstance
  let childPosition
  let parentPosition
  let fullPosition

  before(async () => {
    deployed = await utils.deploySystem(DEPLOY)
    positionInstance = deployed.PositionStub
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

  describe("slot()", async () => {
    it("Returns the last bits", async () => {
      const result = await positionInstance.slot.call(fullPosition)
      assert.equal(result, childPosition)
    })
  })

  describe("parent()", async () => {
    it("Returns the first bits", async () => {
      const result = await positionInstance.parent.call(fullPosition)
      assert.equal(result, parentPosition)
    })
  })

  describe("child()", async () => {
    it("Returns the child address", async () => {
      const result = await positionInstance.child.call(
        parentPosition,
        childPosition,
      )
      assert.equal(result, fullPosition)
    })
  })
})
