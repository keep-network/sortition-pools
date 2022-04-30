const { expect } = require("chai")

describe("RNG", () => {
  let rngInstance

  beforeEach(async () => {
    const RNGStub = await ethers.getContractFactory("RNGStub")
    rngInstance = await RNGStub.deploy()
    await rngInstance.deployed()
  })

  describe("bitsRequired", async () => {
    it("Returns the number of bits required", async () => {
      // Any number higher than 2**32 will just return 32
      expect(await rngInstance.bitsRequired(2 ** 32 + 1)).to.be.equal(32)
      expect(await rngInstance.bitsRequired(2 ** 32)).to.be.equal(32)
      expect(await rngInstance.bitsRequired(2 ** 32 - 1)).to.be.equal(32)

      expect(await rngInstance.bitsRequired(2 ** 31 + 1)).to.be.equal(32)
      expect(await rngInstance.bitsRequired(2 ** 31)).to.be.equal(31)
      expect(await rngInstance.bitsRequired(2 ** 31 - 1)).to.be.equal(31)

      expect(await rngInstance.bitsRequired(2 ** 16 + 1)).to.be.equal(17)
      expect(await rngInstance.bitsRequired(2 ** 16)).to.be.equal(16)
      expect(await rngInstance.bitsRequired(2 ** 16 - 1)).to.be.equal(16)

      expect(await rngInstance.bitsRequired(2 ** 2 + 1)).to.be.equal(3)
      expect(await rngInstance.bitsRequired(2 ** 2)).to.be.equal(2)
      expect(await rngInstance.bitsRequired(2 ** 2 - 1)).to.be.equal(2)

      expect(await rngInstance.bitsRequired(2)).to.be.equal(1)

      // Generative Testing
      const numberOfSamples = 100
      const maxNumber = 2 ** 32 - 1
      for (let i = 0; i < numberOfSamples; i++) {
        const randomNumber = Math.floor(Math.random() * maxNumber)
        const bitsRequired = await rngInstance.bitsRequired(randomNumber)
        // We can represent 0 and 1 with 1 bit, 0-3 with 2 bits, 0-7 with 3
        // bits, etc. Every bit doubles the number of numbers we can represent,
        // so working backwards is log base 2.
        const expectation = Math.ceil(Math.log2(randomNumber))
        expect(bitsRequired).to.equal(
          expectation,
          `something went wrong calculating the bits required for ${randomNumber}`,
        )
      }
    })
  })

  describe("truncate", async () => {
    it("Truncates a number to the correct number of bits", async () => {
      const a = 0xffffffff

      const b = await rngInstance.truncate(1, a)
      const c = await rngInstance.truncate(2, a)
      const d = await rngInstance.truncate(16, a)
      const e = await rngInstance.truncate(31, a)
      const f = await rngInstance.truncate(32, a)
      const g = await rngInstance.truncate(64, a)

      expect(b).to.be.equal(0x1)
      expect(c).to.be.equal(0x3)
      expect(d).to.be.equal(0xffff)
      expect(e).to.be.equal(0x7fffffff)
      expect(f).to.be.equal(a)
      expect(g).to.be.equal(a)
    })
  })

  describe("getIndex", async () => {
    it("Returns an index smaller than the range", async () => {
      r = 0x12345
      s = 0x0deadbeef

      i = await rngInstance.getIndex(r, s)

      const hex = ethers.utils.hexlify(i)
      const num = ethers.BigNumber.from(hex)
      expect(num).to.be.below(r)
    })
  })
})
