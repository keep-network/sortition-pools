const RNG = artifacts.require("./contracts/RNG.sol")
const RNGStub = artifacts.require("RNGStub.sol")

const toHex = web3.utils.numberToHex
const toNum = web3.utils.hexToNumber
const utils = require("./utils")

const DEPLOY = [
  { name: "RNG", contract: RNG },
  { name: "RNGStub", contract: RNGStub },
]

contract("RNG", () => {
  let rngInstance

  before(async () => {
    deployed = await utils.deploySystem(DEPLOY)
    rngInstance = deployed.RNGStub
  })

  describe("bitsRequired()", async () => {
    it("Returns the number of bits required", async () => {
      assert.equal(await rngInstance.bitsRequired.call(2 ** 32 + 1), 32)
      assert.equal(await rngInstance.bitsRequired.call(2 ** 32), 32)
      assert.equal(await rngInstance.bitsRequired.call(2 ** 32 - 1), 32)

      assert.equal(await rngInstance.bitsRequired.call(2 ** 31 + 1), 32)
      assert.equal(await rngInstance.bitsRequired.call(2 ** 31), 31)
      assert.equal(await rngInstance.bitsRequired.call(2 ** 31 - 1), 31)

      assert.equal(await rngInstance.bitsRequired.call(2 ** 16 + 1), 17)
      assert.equal(await rngInstance.bitsRequired.call(2 ** 16), 16)
      assert.equal(await rngInstance.bitsRequired.call(2 ** 16 - 1), 16)

      assert.equal(await rngInstance.bitsRequired.call(2 ** 2 + 1), 3)
      assert.equal(await rngInstance.bitsRequired.call(2 ** 2), 2)
      assert.equal(await rngInstance.bitsRequired.call(2 ** 2 - 1), 2)

      assert.equal(await rngInstance.bitsRequired.call(2), 1)
    })
  })

  describe("truncate()", async () => {
    it("Truncates a number to the correct number of bits", async () => {
      a = 0xffffffff

      b = await rngInstance.truncate.call(1, a)
      c = await rngInstance.truncate.call(2, a)
      d = await rngInstance.truncate.call(16, a)
      e = await rngInstance.truncate.call(31, a)
      f = await rngInstance.truncate.call(32, a)
      g = await rngInstance.truncate.call(64, a)

      assert.equal(b, 0x1)
      assert.equal(c, 0x3)
      assert.equal(d, 0xffff)
      assert.equal(e, 0x7fffffff)
      assert.equal(f, a)
      assert.equal(g, a)
    })
  })

  describe("getIndex()", async () => {
    it("Returns an index smaller than the range", async () => {
      r = 0x12345
      s = 0x0deadbeef

      i = await rngInstance.getIndex.call(r, s)

      assert.isBelow(toNum(toHex(i)), r)
    })
  })
})
