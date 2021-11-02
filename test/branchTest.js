const { BigNumber } = require("ethers")
const { expect } = require("chai")

describe("Branch", () => {
  const node = BigNumber.from(
    "0x7777777766666666555555554444444433333333222222221111111100000000",
  )
  let branchInstance
  let testBranch

  beforeEach(async () => {
    const BranchStub = await ethers.getContractFactory("BranchStub")
    branchInstance = await BranchStub.deploy()
    await branchInstance.deployed()

    const TestBranch = await ethers.getContractFactory("TestBranch")
    testBranch = await TestBranch.deploy()
    await testBranch.deployed()
  })

  describe("getSlot", async () => {
    it("Returns the uint16 in the correct position", async () => {
      const result = await branchInstance.getSlot(node, 3)
      expect(result).to.be.equal(0x33333333)
    })
  })

  describe("clearSlot", async () => {
    it("Clears the correct slot", async () => {
      newNode =
        "0x7777777766666666555555554444444400000000222222221111111100000000"

      const result = await branchInstance.clearSlot(node, 3)
      expect(ethers.utils.hexlify(result)).to.be.equal(newNode)
    })
  })

  describe("setSlot", async () => {
    it("Changes the correct slot", async () => {
      newNode =
        "0x7777777766666666555555554444444412345678222222221111111100000000"
      w = 0x12345678

      const modified = await branchInstance.setSlot(node, 3, w)
      newSlot = await branchInstance.getSlot(modified, 3)
      expect(ethers.utils.hexlify(modified)).to.be.equal(newNode)
    })
  })

  describe("sumWeight", async () => {
    it("Returns the correct weight", async () => {
      const weight = await branchInstance.sumWeight(node)
      const expected = 0x77777777 * 4
      expect(weight).to.be.equal(expected)
    })
  })

  describe("pickWeightedSlot", async () => {
    it("runPickWeightedSlotTest", async () => {
      await testBranch.runPickWeightedSlotTest()
      // ok, no revert
    })
  })
})
