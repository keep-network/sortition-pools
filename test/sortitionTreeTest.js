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
      it("should return correct value for the tree", async () => {
        const weight = 0x1234
        const position = 42798

        const leaf = await sortition.toLeaf(alice.address, weight)
        await sortition.publicSetLeaf(position, leaf, weight)
        const root = await sortition.getRoot()
        //
        // Since the only leaf in the tree is the one we set, that's the only
        // weight that propagates to the root node. The first slot in the root
        // covers the sum of the first 8^6 = 262144 leaves. The next slot in
        // the root covers the sum of the next 262144, and so on.
        expect(ethers.utils.hexlify(root)).to.be.equal("0x1234")
        // The full output here looks like
        // 0x00000000,00000000,00000000,00000000,00000000,00000000,00000000,00001234
        //  slot 7     slot 6   slot 5   slot 4   slot 3   slot 2   slot 1   slot 0
        // without the commas added for readability. All the padding zeros are
        // dropped when we hexlify.
      })
    })

    it("should return correct value for the tree with a leaf in a second slot", async () => {
      const weight = 0x1234
      const position = 262145

      const leaf = await sortition.toLeaf(alice.address, weight)
      await sortition.publicSetLeaf(position, leaf, weight)
      const root = await sortition.getRoot()
      //
      // Since the only leaf in the tree is the one we set, that's the only
      // weight that propagates to the root node. The first slot in the root
      // covers the sum of the first 8^6 = 262144 leaves. The next slot in
      // the root covers the sum of the next 262144, and so on.
      expect(ethers.utils.hexlify(root)).to.be.equal("0x123400000000")
      // The full output here looks like
      // 0x00000000,00000000,00000000,00000000,00000000,00000000,00001234,00000000
      //  slot 7     slot 6   slot 5   slot 4   slot 3   slot 2   slot 1   slot 0
      // without the commas added for readability. All the padding zeros are
      // dropped when we hexlify, which simplifies to 0x123400000000.
    })

    context("when two leaves are set", () => {
      it("should return correct value for the tree", async () => {
        const weight1 = 0x1234
        const position1 = 42798

        const weight2 = 0x11
        const position2 = 342391

        const leaf1 = await sortition.toLeaf(alice.address, weight1)
        await sortition.publicSetLeaf(position1, leaf1, weight1)

        const leaf2 = await sortition.toLeaf(bob.address, weight2)
        await sortition.publicSetLeaf(position2, leaf2, weight2)
        const root = await sortition.getRoot()
        expect(ethers.utils.hexlify(root)).to.be.equal("0x1100001234")
        // The full output here looks like
        // 0x00000000,00000000,00000000,00000000,00000000,00000000,00000011,00001234
        //  slot 7     slot 6   slot 5   slot 4   slot 3   slot 2   slot 1   slot 0
        // without the commas added for readability. All the padding zeros are
        // dropped when we hexlify, which simplifies to 0x1100001234.
      })
    })
  })

  describe("removeLeaf", () => {
    context("when leaf is removed", () => {
      it("should return correct value for the tree", async () => {
        const weight1 = 0x1234
        const position1 = 42798

        const weight2 = 0x11
        const position2 = 342391

        const leaf1 = await sortition.toLeaf(alice.address, weight1)
        await sortition.publicSetLeaf(position1, leaf1, weight1)

        const leaf2 = await sortition.toLeaf(bob.address, weight2)
        await sortition.publicSetLeaf(position2, leaf2, weight2)
        await sortition.publicRemoveLeaf(position1)
        const root = await sortition.getRoot()
        expect(ethers.utils.hexlify(root)).to.be.equal("0x1100000000")
        // The full output here looks like
        // 0x00000000,00000000,00000000,00000000,00000000,00000000,00000011,00000000
        //  slot 7     slot 6   slot 5   slot 4   slot 3   slot 2   slot 1   slot 0
        // without the commas added for readability. All the padding zeros are
        // dropped when we hexlify, which simplifies to 0x1100000000.
      })
    })
  })

  describe("insertOperator", () => {
    const weightA = 0xfff0
    const weightB = 0x10000001
    // weightA + weightB = 0x1000fff1

    context("when operators are inserted", () => {
      it("should return correct value for the tree", async () => {
        // insertion begins left to right, so alice is inserted at position 0,
        // and bob is inserted at position 1. Their weights will propagate to
        // the root's first slot.
        await sortition.publicInsertOperator(alice.address, weightA)
        await sortition.publicInsertOperator(bob.address, weightB)
        const root = await sortition.getRoot()
        expect(ethers.utils.hexlify(root)).to.be.equal("0x1000fff1") // weightA + weightB
        // The full output here looks like
        // 0x00000000,00000000,00000000,00000000,00000000,00000000,00000000,1000fff1
        //  slot 7     slot 6   slot 5   slot 4   slot 3   slot 2   slot 1   slot 0
        // without the commas added for readability. All the padding zeros are
        // dropped when we hexlify, which simplifies to 0x1100000000.
      })
    })

    context("when operator is already registered", () => {
      it("should revert", async () => {
        await sortition.publicInsertOperator(alice.address, weightA)
        await expect(
          sortition.publicInsertOperator(alice.address, weightB),
        ).to.be.revertedWith("Operator is already registered in the pool")
      })
    })
  })

  describe("getOperatorID", () => {
    context("when operator is inserted", () => {
      it("should return the id of the operator", async () => {
        await sortition.publicInsertOperator(alice.address, 0xfff0)
        const aliceID = await sortition.getOperatorID(alice.address)
        expect(aliceID).to.be.equal(1)
      })
    })

    it("should return zero id when the operator is unknown", async () => {
      const bobID = await sortition.getOperatorID(bob.address)
      expect(bobID).to.be.equal(0)
    })
  })

  describe("getIDOperator", () => {
    context("when operator is inserted", () => {
      it("should return the address of the operator by their id", async () => {
        await sortition.publicInsertOperator(alice.address, 0xfff0)
        const aliceAddress = await sortition.getIDOperator(1)
        expect(aliceAddress).to.be.equal(alice.address)
      })
    })

    it("should return zero address when the id of operator is unknown", async () => {
      const aliceAddress = await sortition.getIDOperator(2)
      expect(aliceAddress).to.be.equal(ZERO_ADDRESS)
    })
  })

  describe("removeOperator", () => {
    context("when operator is not registered", () => {
      it("should revert", async () => {
        await sortition.publicInsertOperator(alice.address, 0x1234)
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
      it("should return false", async () => {
        await sortition.publicInsertOperator(alice.address, 0x1234)
        expect(await sortition.publicIsOperatorRegistered(bob.address)).to.be
          .false
      })
    })

    context("when operator is registered", () => {
      it("should return false", async () => {
        await sortition.publicInsertOperator(alice.address, 0x1234)
        expect(await sortition.publicIsOperatorRegistered(alice.address)).to.be
          .true
      })
    })
  })

  describe("updateLeaf", async () => {
    context("when leaf is updated", () => {
      it("should return the correct value for the root", async () => {
        await sortition.publicInsertOperator(alice.address, 0x1234)
        await sortition.publicUpdateLeaf(0x00000, 0x9876)
        const root = await sortition.getRoot()
        expect(ethers.utils.hexlify(root)).to.be.equal("0x9876")
      })
    })
  })

  describe("trunk stacks", async () => {
    it("works as expected", async () => {
      // inserted in the first position
      await sortition.publicInsertOperator(alice.address, 0x1234)
      // inserted in the second position
      await sortition.publicInsertOperator(bob.address, 0x9876)

      await sortition.publicRemoveOperator(alice.address)
      const deletedLeaf = await sortition.getLeaf(0x00000)
      expect(deletedLeaf).to.be.equal(0)

      // the first position isn't reused until we've inserted 8^7 = 2097152
      // operators. Alice is inserted in the third position.
      await sortition.publicInsertOperator(alice.address, 0xdead)

      const stillDeletedLeaf = await sortition.getLeaf(0x00000)
      expect(stillDeletedLeaf).to.be.equal(0)

      const root = await sortition.getRoot()
      // 0x9876 + 0xdead = 0x17723
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
      it("should return true", async () => {
        await sortition.publicInsertOperator(alice.address, 1)
        const nOperators = await sortition.operatorsInPool()
        expect(nOperators).to.be.equal(1)
      })
    })
  })

  describe("getIDOperators", async () => {
    it("returns operator addresses", async () => {
      await sortition.publicInsertOperator(alice.address, 0xfff)
      await sortition.publicInsertOperator(bob.address, 0x123)

      const aliceID = 1
      const bobID = 2
      const unknownID = 9

      const addresses = await sortition.getIDOperators([
        aliceID,
        unknownID,
        bobID,
      ])
      expect(addresses.length).to.equal(3)
      expect(addresses[0]).to.equal(alice.address)
      expect(addresses[1]).to.equal(ZERO_ADDRESS)
      expect(addresses[2]).to.equal(bob.address)
    })
  })
})
