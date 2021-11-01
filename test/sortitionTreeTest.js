const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants")
const { expect } = require("chai")

describe("SortitionTree", () => {
  let sortition
  let alice
  let bob

  beforeEach(async () => {
    alice = await ethers.getSigner(0)
    bob = await ethers.getSigner(1)

    const SortitionTreeStub = await ethers.getContractFactory(
      "SortitionTreeStub",
    )
    sortition = await SortitionTreeStub.deploy()
    await sortition.deployed()
  })

  describe("setLeaf", async () => {
    context("when one leaf is set", () => {
      beforeEach(async () => {
        const weight1 = 0x1234
        const position1 = parseInt("00123456", 8)

        const leaf = await sortition.toLeaf(alice.address, weight1)
        await sortition.publicSetLeaf(position1, leaf, weight1)
      })

      it("should return correct value for the tree", async () => {
        const root = await sortition.getRoot()
        expect(ethers.utils.hexlify(root)).to.be.equal("0x1234")
      })
    })

    context("when two leaves are set", () => {
      beforeEach(async () => {
        const weight1 = 0x1234
        const position1 = parseInt("00123456", 8)
        const weight2 = 0x11
        const position2 = parseInt("01234567", 8)

        const leaf1 = await sortition.toLeaf(alice.address, weight1)
        await sortition.publicSetLeaf(position1, leaf1, weight1)

        const leaf2 = await sortition.toLeaf(bob.address, weight2)
        await sortition.publicSetLeaf(position2, leaf2, weight2)
      })

      it("should return correct value for the tree", async () => {
        const root = await sortition.getRoot()
        expect(ethers.utils.hexlify(root)).to.be.equal("0x1100001234")
      })
    })
  })

  describe("removeLeaf", () => {
    context("when leaf is removed", () => {
      beforeEach(async () => {
        const weight1 = 0x1234
        const position1 = parseInt("00123456", 8)
        const weight2 = 0x11
        const position2 = parseInt("01234567", 8)

        const leaf1 = await sortition.toLeaf(alice.address, weight1)
        await sortition.publicSetLeaf(position1, leaf1, weight1)

        const leaf2 = await sortition.toLeaf(bob.address, weight2)
        await sortition.publicSetLeaf(position2, leaf2, weight2)
        await sortition.publicRemoveLeaf(position1)
      })

      it("should return correct value for the tree", async () => {
        const root = await sortition.getRoot()
        expect(ethers.utils.hexlify(root)).to.be.equal("0x1100000000")
      })
    })
  })

  describe("insertOperator", () => {
    const weightA = 0xfff0
    const weightB = 0x10000001

    context("when operators are inserted", () => {
      beforeEach(async () => {
        await sortition.publicInsertOperator(alice.address, weightA)
        await sortition.publicInsertOperator(bob.address, weightB)
      })

      it("should return correct value for the tree", async () => {
        const root = await sortition.getRoot()
        expect(ethers.utils.hexlify(root)).to.be.equal("0x1000fff1")
      })
    })

    context("when operator is already registered", () => {
      beforeEach(async () => {
        await sortition.publicInsertOperator(alice.address, weightA)
      })

      it("should revert", async () => {
        await expect(
          sortition.publicInsertOperator(alice.address, weightB),
        ).to.be.revertedWith("Operator is already registered in the pool")
      })
    })
  })

  describe("getOperatorID", () => {
    context("when operator is inserted", () => {
      beforeEach(async () => {
        await sortition.publicInsertOperator(alice.address, 0xfff0)
      })

      it("should return the id of the operator", async () => {
        const aliceID = await sortition.getOperatorID(alice.address)
        expect(aliceID).to.be.equal(1)
      })

      it("should return zero id when the operator is unknown", async () => {
        const bobID = await sortition.getOperatorID(bob.address)
        expect(bobID).to.be.equal(0)
      })
    })
  })

  describe("getIDOperator", () => {
    context("when operator is inserted", () => {
      beforeEach(async () => {
        await sortition.publicInsertOperator(alice.address, 0xfff0)
      })

      it("should return the address of the operator by their id", async () => {
        const aliceAddress = await sortition.getIDOperator(1)
        expect(aliceAddress).to.be.equal(alice.address)
      })

      it("should return zero address when the id of operator is unknown", async () => {
        const aliceAddress = await sortition.getIDOperator(2)
        expect(aliceAddress).to.be.equal(ZERO_ADDRESS)
      })
    })
  })

  describe("removeOperator", () => {
    context("when operator is not registered", () => {
      beforeEach(async () => {
        await sortition.publicInsertOperator(alice.address, 0x1234)
      })

      it("should revert", async () => {
        await expect(
          sortition.publicRemoveOperator(bob.address),
        ).to.be.revertedWith("Operator is not registered in the pool")
      })
    })

    context("when operator is registered", () => {
      beforeEach(async () => {
        await sortition.publicInsertOperator(alice.address, 0x1234)
        await sortition.publicRemoveOperator(alice.address)
      })

      it("should return correct value for the root", async () => {
        const root = await sortition.getRoot()
        expect(ethers.utils.hexlify(root)).to.be.equal("0x00")
      })

      it("should return 0 for flagged leaf position", async () => {
        const aliceLeaf = await sortition.publicGetFlaggedLeafPosition(
          alice.address,
        )
        expect(aliceLeaf).to.be.equal(0)
      })

      it("should not remove the id of the operator", async () => {
        const aliceID = await sortition.getOperatorID(alice.address)
        expect(aliceID).to.be.equal(1)
      })
    })
  })

  describe("isOperatorRegistered", async () => {
    context("when operator is not registered", () => {
      beforeEach(async () => {
        await sortition.publicInsertOperator(alice.address, 0x1234)
      })

      it("should return false", async () => {
        expect(await sortition.publicIsOperatorRegistered(bob.address)).to.be
          .false
      })
    })

    context("when operator is registered", () => {
      beforeEach(async () => {
        await sortition.publicInsertOperator(alice.address, 0x1234)
      })

      it("should return false", async () => {
        expect(await sortition.publicIsOperatorRegistered(alice.address)).to.be
          .true
      })
    })
  })

  describe("updateLeaf", async () => {
    context("when leaf is updated", () => {
      beforeEach(async () => {
        await sortition.publicInsertOperator(alice.address, 0x1234)
        await sortition.publicUpdateLeaf(0x00000, 0x9876)
      })

      it("should return the correct value for the root", async () => {
        const root = await sortition.getRoot()
        expect(ethers.utils.hexlify(root)).to.be.equal("0x9876")
      })
    })
  })

  describe("trunk stacks", async () => {
    it("works as expected", async () => {
      await sortition.publicInsertOperator(alice.address, 0x1234)
      await sortition.publicInsertOperator(bob.address, 0x9876)

      await sortition.publicRemoveOperator(alice.address)
      const deletedLeaf = await sortition.getLeaf(0x00000)
      expect(deletedLeaf).to.be.equal(0)

      await sortition.publicInsertOperator(alice.address, 0xdead)

      const stillDeletedLeaf = await sortition.getLeaf(0x00000)
      expect(stillDeletedLeaf).to.be.equal(0)

      const root = await sortition.getRoot()
      expect(ethers.utils.hexlify(root)).to.be.equal("0x017723")
    })
  })

  describe("leaf selection", async () => {
    it("works as expected", async () => {
      await sortition.publicInsertOperator(alice.address, 451)
      await sortition.publicInsertOperator(bob.address, 1984)
      const index1 = 450
      const index2 = 451

      const position1 = await sortition.publicPickWeightedLeaf(index1)
      expect(position1).to.be.equal(0)

      const leaf1 = await sortition.getLeaf(position1)
      const address1 = await sortition.leafAddress(leaf1)
      expect(address1).to.be.equal(alice.address)

      const position2 = await sortition.publicPickWeightedLeaf(index2)
      expect(position2).to.be.equal(1)

      const leaf2 = await sortition.getLeaf(position2)
      const address2 = await sortition.leafAddress(leaf2)
      expect(address2).to.be.equal(bob.address)
    })
  })

  describe("operatorsInPool", async () => {
    context("when the operator is in the pool", () => {
      beforeEach(async () => {
        await sortition.publicInsertOperator(alice.address, 1)
      })

      it("should return true", async () => {
        const nOperators = await sortition.operatorsInPool()
        expect(nOperators).to.be.equal(1)
      })
    })
  })

  describe("getIDOperators", async () => {
    it("returns operator addresses", async () => {
      const weight = 0xfff
      await sortition.publicInsertOperator(alice, weight)
      await sortition.publicInsertOperator(bob, weight)

      const aliceID = 1
      const bobID = 2
      const unknownID = 9

      const addresses = await sortition.getIDOperators.call([
        aliceID,
        unknownID,
        bobID,
      ])
      assert.equal(addresses.length, 3)
      assert.equal(addresses[0], alice)
      assert.equal(addresses[1], 0x0)
      assert.equal(addresses[2], bob)
    })
  })
})
