const { expect } = require("chai")

describe("Position", async () => {
  let positionInstance
  const maxPosition = Math.pow(8, 7) // max number of operators

  beforeEach(async () => {
    const PositionStub = await ethers.getContractFactory("PositionStub")
    positionInstance = await PositionStub.deploy()
    await positionInstance.deployed()
  })

  describe("slot", async () => {
    it("Returns the slot of a node in its parent", async () => {
      // Sample Cases
      //
      // The first position gets the first slot in the first parent, the
      // second gets the second slot in the first parent, and so on, until
      // the 9th, which gets the first slot in the second parent. Thus, the
      // slot is just `position % 8`.
      const testData = [
        {
          position: 196831,
          slot: 7,
        },
        {
          position: 238968,
          slot: 0,
        },
        {
          position: 31002,
          slot: 2,
        },
        {
          position: 1617940,
          slot: 4,
        },
      ]
      for (let i = 0; i < testData.length; i++) {
        const test = testData[i]
        const slot = await positionInstance.slot(test.position)
        expect(slot).to.equal(
          test.slot,
          `unexpected result for test index ${i}`,
        )
      }

      // Generative Testing
      const numSamples = 100
      for (let i = 0; i < numSamples; i++) {
        // generate a random position in [0, maxPosition)
        const position = Math.floor(Math.random() * maxPosition)
        const slot = await positionInstance.slot(position)
        const expectation = position % 8
        expect(slot).to.equal(
          expectation,
          `unexpected result for position ${position}`,
        )
      }
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
