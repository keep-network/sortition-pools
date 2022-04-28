const { BigNumber } = require("ethers")
const { expect } = require("chai")

describe("Leaf", () => {
  let leafInstance

  beforeEach(async () => {
    const LeafStub = await ethers.getContractFactory("LeafStub")
    leafInstance = await LeafStub.deploy()
    await leafInstance.deployed()
  })

  describe("make", async () => {
    it("constructs a leaf", async () => {
      // We store a leaf as a uint256, which is 256 bits. We pack the address
      // in the first 160 bits, the creation block in the 64 bits after that,
      // and the operator's id in the final 32 bits. Each hex character
      // represents 4 bits, so a 40-character hex representation of an eth
      // address is the exact 160 bits we need. A number (like a creation block
      // or id) is little-endian and gets left-padded with zeros to fill the
      // exact bit count.
      const testData = [
        {
          address: "0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5",
          creationBlock: BigNumber.from("0xDFD871"),
          id: 0x1995b5,
          expectation:
            "0x4ddc2d193948926d02f9b1fe9e1daa0718270ed50000000000DFD871001995B5",
          //     read:    4ddc2d193948926d02f9b1fe9e1daa0718270ed5,0000000000DFD871,001995B5
          //                    address                             creationBlock     id
        },
        {
          address: "0x176f3dab24a159341c0509bb36b833e7fdd0a132",
          creationBlock: BigNumber.from("0x5E8EEE0"),
          id: 0x8f573,
          expectation:
            "0x176f3dab24a159341c0509bb36b833e7fdd0a1320000000005E8EEE00008F573",
          //     read:    176f3dab24a159341c0509bb36b833e7fdd0a132,0000000005E8EEE0,0008F573
          //                    address                             creationBlock     id
        },
        {
          address: "0x2b6ed29a95753c3ad948348e3e7b1a251080ffb9",
          creationBlock: BigNumber.from("0x771D8DB"),
          id: 0xca009,
          expectation:
            "0x2b6ed29a95753c3ad948348e3e7b1a251080ffb9000000000771D8DB000CA009",
          //     read:    2b6ed29a95753c3ad948348e3e7b1a251080ffb9,000000000771D8DB,000CA009
          //                    address                             creationBlock     id
        },
      ]

      for (let i = 0; i < testData.length; i++) {
        const test = testData[i]
        const leaf = await leafInstance.make(
          test.address,
          test.creationBlock,
          test.id,
        )
        expect(leaf).to.equal(test.expectation)
      }
    })
  })

  describe("operator", async () => {
    it("retrieves the operator from the leaf", async () => {
      const testData = [
        {
          leaf: "0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED50000000000DFD871001995B5",
          //       4Ddc2D193948926D02f9B1fE9e1daa0718270ED5,0000000000DFD871,001995B5
          //              address                             creationBlock     id
          operator: "0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5",
        },
        {
          leaf: "0x176F3DAb24a159341c0509bB36B833E7fdd0a1320000000005E8EEE00008F573",
          //       176F3DAb24a159341c0509bB36B833E7fdd0a132,0000000005E8EEE0,0008F573
          //              address                             creationBlock     id
          operator: "0x176F3DAb24a159341c0509bB36B833E7fdd0a132",
        },
        {
          leaf: "0x2B6eD29A95753C3Ad948348e3e7b1A251080Ffb9000000000771D8DB000CA009",
          //       2B6eD29A95753C3Ad948348e3e7b1A251080Ffb9,000000000771D8DB,000CA009
          //              address                             creationBlock     id
          operator: "0x2B6eD29A95753C3Ad948348e3e7b1A251080Ffb9",
        },
      ]

      for (let i = 0; i < testData.length; i++) {
        const test = testData[i]
        const operator = await leafInstance.operator(BigNumber.from(test.leaf))
        expect(operator).to.equal(test.operator)
      }
    })
  })

  describe("creationBlock", async () => {
    it("retrieves the creation block from the leaf", async () => {
      const testData = [
        {
          leaf: "0x4ddc2d193948926d02f9b1fe9e1daa0718270ed50000000000DFD871001995B5",
          //       4ddc2d193948926d02f9b1fe9e1daa0718270ed5,0000000000DFD871,001995B5
          //              address                             creationBlock     id
          creationBlock: "0xDFD871",
        },
        {
          leaf: "0x176f3dab24a159341c0509bb36b833e7fdd0a1320000000005E8EEE00008F573",
          //       176f3dab24a159341c0509bb36b833e7fdd0a132,0000000005E8EEE0,0008F573
          //              address                             creationBlock     id
          creationBlock: "0x5E8EEE0",
        },
        {
          leaf: "0x2b6ed29a95753c3ad948348e3e7b1a251080ffb9000000000771D8DB000CA009",
          //       2b6ed29a95753c3ad948348e3e7b1a251080ffb9,000000000771D8DB,000CA009
          //              address                             creationBlock     id
          creationBlock: "0x771D8DB",
        },
      ]

      for (let i = 0; i < testData.length; i++) {
        const test = testData[i]
        const creationBlock = await leafInstance.creationBlock(
          BigNumber.from(test.leaf),
        )
        expect(creationBlock).to.equal(test.creationBlock)
      }
    })
  })

  describe("id", async () => {
    it("retrives the operator's id from the leaf", async () => {
      const testData = [
        {
          leaf: "0x4ddc2d193948926d02f9b1fe9e1daa0718270ed50000000000DFD871001995B5",
          //       4ddc2d193948926d02f9b1fe9e1daa0718270ed5,0000000000DFD871,001995B5
          //              address                             creationBlock     id
          id: "0x1995B5",
        },
        {
          leaf: "0x176f3dab24a159341c0509bb36b833e7fdd0a1320000000005E8EEE00008F573",
          //       176f3dab24a159341c0509bb36b833e7fdd0a132,0000000005E8EEE0,0008F573
          //              address                             creationBlock     id
          id: "0x8F573",
        },
        {
          leaf: "0x2b6ed29a95753c3ad948348e3e7b1a251080ffb9000000000771D8DB000CA009",
          //       2b6ed29a95753c3ad948348e3e7b1a251080ffb9,000000000771D8DB,000CA009
          //              address                             creationBlock     id
          id: "0xCA009",
        },
      ]
      for (let i = 0; i < testData.length; i++) {
        const test = testData[i]
        const id = await leafInstance.id(BigNumber.from(test.leaf))
        expect(id).to.equal(parseInt(test.id, 16))
      }
    })
  })
})
