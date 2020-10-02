const {contract, web3} = require("@openzeppelin/test-environment")

const Branch = contract.fromArtifact("Branch")
const BranchStub = contract.fromArtifact("BranchStub")

const toHex = web3.utils.numberToHex
const utils = require("./helpers/utils")

const BN = web3.utils.BN

const chai = require("chai")
const assert = chai.assert

const DEPLOY = [
  {name: "Branch", contract: Branch},
  {name: "BranchStub", contract: BranchStub},
]
const node = new BN(
  "0x7777777766666666555555554444444433333333222222221111111100000000",
  16,
)

describe("Branch", () => {
  let branchInstance

  before(async () => {
    deployed = await utils.deploySystem(DEPLOY)
    branchInstance = deployed.BranchStub
  })

  describe("getSlot()", async () => {
    it("Returns the uint16 in the correct position", async () => {
      const result = await branchInstance.getSlot.call(node, 3)
      assert.equal(result, 0x33333333)
    })
  })

  describe("clearSlot()", async () => {
    it("Clears the correct slot", async () => {
      newNode =
        "0x7777777766666666555555554444444400000000222222221111111100000000"

      const result = await branchInstance.clearSlot.call(node, 3)
      assert.equal(toHex(result), newNode)
    })
  })

  describe("setSlot()", async () => {
    it("Changes the correct slot", async () => {
      newNode =
        "0x7777777766666666555555554444444412345678222222221111111100000000"
      w = 0x12345678

      const modified = await branchInstance.setSlot.call(node, 3, w)
      newSlot = await branchInstance.getSlot.call(modified, 3)
      assert.equal(toHex(modified), newNode)
    })
  })

  describe("sumWeight()", async () => {
    it("Returns the correct weight", async () => {
      const weight = await branchInstance.sumWeight.call(node)
      expected = 0x77777777 * 4
      assert.equal(weight, expected)
    })
  })
})
