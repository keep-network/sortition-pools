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

      // Generative Testing
      const numberOfSamples = 3
      const maxNumber = 2 ** 32 - 1
      for (let i = 0; i < numberOfSamples; i++) {
        // Truncating to `bits` is mathematically equivalent to
        // `number % (2 ** bits)`
        for (let bits = 1; bits < 65; bits++) {
          const randomNumber = Math.floor(Math.random() * maxNumber)
          const truncatedNumber = await rngInstance.truncate(bits, randomNumber)
          const expectation = randomNumber % 2 ** bits
          expect(truncatedNumber).to.be.equal(
            expectation,
            `something went wrong truncating ${randomNumber} to ${bits} bits`,
          )
        }
      }
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

    it("Produces a uniform distribution", async () => {
      // Algorithm adapted from
      // https://www.rosettacode.org/wiki/Verify_distribution_uniformity/Naive#JavaScript
      //
      // We sample the distribution, and then make sure that the count of any
      // generated number doesn't exceed a tolerance.

      const delta = 10 // percentage degree of inaccuracy to tolerate
      const maxSeed = 2 ** 32

      // Use a low number of possible outcomes but a large number of samples to
      // make good use of the time-costly runtime to evaluate uniformity.
      // Higher number of possible outcomes would require higher number of
      // samples.
      const maxNumber = 6
      const numSamples = 10000
      const count = {}
      for (let i = 0; i < numSamples; i++) {
        const val = await rngInstance.getIndex(
          maxNumber,
          Math.floor(Math.random() * maxSeed),
        )
        // Count the number of occurences of each random number
        count[val] = (count[val] || 0) + 1
      }
      const vals = Object.keys(count)

      const target = numSamples / maxNumber

      // Tolerate counts that are within delta% of true uniformity
      const tolerance = (target * delta) / 100

      for (let i = 0; i < vals.length; i++) {
        const val = vals[i]
        const distance = Math.abs(count[val] - target)
        expect(distance).to.be.below(
          tolerance,
          `${val}'s count of ${count[val]}] was too far away from the uniform expectation of ${target}`,
        )
      }
    })
  })
})
