const { BigNumber } = require("ethers")
const { expect } = require("chai")

describe("Branch", () => {
  // A branch is a uint256, meaning it's represented with 256 bits. Each branch
  // represents 8 children, where each child gets 32 sequential bits. A hex
  // number represents 4 bits, so an 8-character long hex string is 32 bits. We
  // store children right-to-left, and use values like 00000000 and 11111111 to
  // make it visually clear where one slot starts and stops.
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
      const expectations = [
        0x00000000, 0x11111111, 0x22222222, 0x33333333, 0x44444444, 0x55555555,
        0x66666666, 0x77777777,
      ]
      for (let slot = 0; slot < 8; slot++) {
        const result = await branchInstance.getSlot(node, slot)
        expect(result).to.equal(expectations[slot])
      }
    })
  })

  describe("clearSlot", async () => {
    it("Clears the correct slot", async () => {
      const expectations = [
        "0x7777777766666666555555554444444433333333222222221111111100000000",
        "0x7777777766666666555555554444444433333333222222220000000000000000",
        "0x7777777766666666555555554444444433333333000000001111111100000000",
        "0x7777777766666666555555554444444400000000222222221111111100000000",
        "0x7777777766666666555555550000000033333333222222221111111100000000",
        "0x7777777766666666000000004444444433333333222222221111111100000000",
        "0x7777777700000000555555554444444433333333222222221111111100000000",
        "0x66666666555555554444444433333333222222221111111100000000",
      ]

      for (let slot = 0; slot < 8; slot++) {
        const result = await branchInstance.clearSlot(node, slot)
        expect(ethers.utils.hexlify(result)).to.equal(expectations[slot])
      }

      // verify that clearing slot 0 actually works!
      const onesNode = BigNumber.from(
        "0x1111111111111111111111111111111111111111111111111111111111111111",
      )
      const result = await branchInstance.clearSlot(onesNode, 0)
      const expectation =
        "0x1111111111111111111111111111111111111111111111111111111100000000"
      expect(ethers.utils.hexlify(result)).to.equal(expectation)
    })
  })

  describe("setSlot", async () => {
    it("Changes the correct slot", async () => {
      const newWeight = 0x12345678
      const expectations = [
        "0x7777777766666666555555554444444433333333222222221111111112345678",
        "0x7777777766666666555555554444444433333333222222221234567800000000",
        "0x7777777766666666555555554444444433333333123456781111111100000000",
        "0x7777777766666666555555554444444412345678222222221111111100000000",
        "0x7777777766666666555555551234567833333333222222221111111100000000",
        "0x7777777766666666123456784444444433333333222222221111111100000000",
        "0x7777777712345678555555554444444433333333222222221111111100000000",
        "0x1234567866666666555555554444444433333333222222221111111100000000",
      ]
      for (let slot = 0; slot < 8; slot++) {
        const result = await branchInstance.setSlot(node, slot, newWeight)
        expect(ethers.utils.hexlify(result)).to.equal(expectations[slot])

        const newSlot = await branchInstance.getSlot(result, slot)
        expect(newSlot).to.equal(newWeight)
      }
    })
  })

  describe("sumWeight", async () => {
    it("Returns the correct weight", async () => {
      const weight = await branchInstance.sumWeight(node)
      const expected =
        0x00000000 +
        0x11111111 +
        0x22222222 +
        0x33333333 +
        0x44444444 +
        0x55555555 +
        0x66666666 +
        0x77777777

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
