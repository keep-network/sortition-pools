const chai = require("chai")
const expect = chai.expect
const { helpers, ethers } = require("hardhat")

describe("SortitionPool", () => {
  const seed =
    "0xff39d6cca87853892d2854566e883008bc000000000000000000000000000000"
  const minStake = 2000
  const poolWeightDivisor = 2000
  let staking
  let pool

  let alice
  let bob
  let carol
  let owner

  beforeEach(async () => {
    alice = await ethers.getSigner(0)
    bob = await ethers.getSigner(1)
    carol = await ethers.getSigner(2)
    owner = await ethers.getSigner(9)

    const StakingContractStub = await ethers.getContractFactory(
      "StakingContractStub",
    )
    staking = await StakingContractStub.deploy()
    await staking.deployed()

    const SortitionPoolStub = await ethers.getContractFactory(
      "SortitionPoolStub",
    )
    pool = await SortitionPoolStub.deploy(
      staking.address,
      minStake,
      poolWeightDivisor,
      owner.address,
    )
    await pool.deployed()
  })

  describe("insertOperator", () => {
    context("when called by the owner", () => {
      context("when operator is eligible", () => {
        beforeEach(async () => {
          await staking.setStake(alice.address, 20000)
          await pool.connect(owner).insertOperator(alice.address)
        })

        it("should insert the operator to the pool", async () => {
          expect(await pool.isOperatorInPool(alice.address)).to.be.true
        })
      })

      context("when operator is not eligible", () => {
        it("should revert", async () => {
          await expect(
            pool.connect(owner).insertOperator(alice.address),
          ).to.be.revertedWith("Operator not eligible")
        })
      })
    })
    context("when called by a non-owner", () => {
      it("should revert", async () => {
        await expect(
          pool.connect(alice).insertOperator(alice.address),
        ).to.be.revertedWith("Caller is not the owner")
      })
    })
  })

  describe("removeOperator", () => {
    let aliceID

    beforeEach(async () => {
      await staking.setStake(alice.address, 20000)
      await pool.connect(owner).insertOperator(alice.address)
      aliceID = await pool.getOperatorID(alice.address)
    })

    context("when called by the owner", () => {
      beforeEach(async () => {
        await pool.connect(owner).removeOperator(aliceID)
      })

      it("should remove the operator from the pool", async () => {
        expect(await pool.isOperatorInPool(alice.address)).to.be.false
      })
    })

    context("when called by a non-owner", () => {
      it("should revert", async () => {
        await expect(
          pool.connect(alice).removeOperator(aliceID),
        ).to.be.revertedWith("Caller is not the owner")
      })
    })
  })

  describe("removeOperators", () => {
    let bobID
    let carolID

    beforeEach(async () => {
      await staking.setStake(alice.address, 20000)
      await staking.setStake(bob.address, 20000)
      await staking.setStake(carol.address, 20000)

      await pool.connect(owner).insertOperator(alice.address)
      await pool.connect(owner).insertOperator(bob.address)
      await pool.connect(owner).insertOperator(carol.address)

      bobID = await pool.getOperatorID(bob.address)
      carolID = await pool.getOperatorID(carol.address)
    })

    context("when called by the owner", () => {
      beforeEach(async () => {
        await pool.connect(owner).removeOperators([bobID, carolID])
      })

      it("should remove given operators from the pool", async () => {
        expect(await pool.isOperatorInPool(alice.address)).to.be.true
        expect(await pool.isOperatorInPool(bob.address)).to.be.false
        expect(await pool.isOperatorInPool(carol.address)).to.be.false
      })
    })

    context("when called by a non-owner", () => {
      it("should revert", async () => {
        await expect(
          pool.connect(alice).removeOperators([bobID, carolID]),
        ).to.be.revertedWith("Caller is not the owner")
      })
    })
  })

  describe("selectGroup", async () => {
    context("when called by owner", () => {
      beforeEach(async () => {
        await staking.setStake(alice.address, 20000)
        await staking.setStake(bob.address, 22000)
        await staking.setStake(carol.address, 24000)
        await pool.connect(owner).insertOperator(alice.address)
        await pool.connect(owner).insertOperator(bob.address)
        await pool.connect(owner).insertOperator(carol.address)
      })

      it("should return group of expected size", async () => {
        const group = await pool.connect(owner).selectGroup(3, seed)
        await pool.connect(owner).nonViewSelectGroup(3, seed)
        expect(group.length).to.be.equal(3)
      })
    })

    context("when called by non-owner", () => {
      beforeEach(async () => {
        await staking.setStake(alice.address, 20000)
        await staking.setStake(bob.address, 22000)
        await staking.setStake(carol.address, 24000)
        await pool.connect(owner).insertOperator(alice.address)
        await pool.connect(owner).insertOperator(bob.address)
        await pool.connect(owner).insertOperator(carol.address)
      })

      it("should revert", async () => {
        await expect(
          pool.connect(alice).selectGroup(3, seed),
        ).to.be.revertedWith("Only owner may select groups")
      })
    })

    context("when there are no operators in the pool", async () => {
      it("should revert", async () => {
        await expect(
          pool.connect(owner).selectGroup(3, seed),
        ).to.be.revertedWith("Not enough operators in pool")
      })
    })

    context(
      "when the number of operators is less than selected group size",
      async () => {
        beforeEach(async () => {
          await staking.setStake(alice.address, 2000)
          await pool.connect(owner).insertOperator(alice.address)
        })

        it("should return group of expected size", async () => {
          const group = await pool.connect(owner).selectGroup(5, seed)
          await pool.connect(owner).nonViewSelectGroup(5, seed)
          expect(group.length).to.be.equal(5)
        })
      },
    )

    context("when operator becomes ineligible", async () => {
      beforeEach(async () => {
        await staking.setStake(alice.address, 2000)
        await staking.setStake(bob.address, 4000000)
        await pool.connect(owner).insertOperator(alice.address)
        await pool.connect(owner).insertOperator(bob.address)

        await staking.setStake(bob.address, 1000)
      })

      it("should not remove the operator", async () => {
        const group = await pool.connect(owner).selectGroup(5, seed)
        await pool.connect(owner).nonViewSelectGroup(5, seed)
        expect(group.length).to.be.equal(5)
      })
    })

    context("when operator becomes outdated", async () => {
      beforeEach(async () => {
        await staking.setStake(alice.address, 2000)
        await staking.setStake(bob.address, 4000000)
        await pool.connect(owner).insertOperator(alice.address)
        await pool.connect(owner).insertOperator(bob.address)

        await staking.setStake(bob.address, 390000)
      })

      it("should not remove the operator", async () => {
        const group = await pool.connect(owner).selectGroup(5, seed)
        await pool.connect(owner).nonViewSelectGroup(5, seed)
        expect(group.length).to.be.equal(5)
      })
    })

    context("when the owner updates outdated operators statuses", (async) => {
      let aliceID
      let bobID

      beforeEach(async () => {
        await staking.setStake(alice.address, 2000)
        await staking.setStake(bob.address, 4000000)
        await pool.connect(owner).insertOperator(alice.address)
        await pool.connect(owner).insertOperator(bob.address)

        aliceID = await pool.getOperatorID(alice.address)
        bobID = await pool.getOperatorID(bob.address)

        await staking.setStake(bob.address, 390000)
        await staking.setStake(alice.address, 1000)

        await helpers.time.mineBlocks(11)

        await pool.connect(owner).updateOperatorStatus(bobID)
        await pool.connect(owner).updateOperatorStatus(aliceID)
      })

      it("should update operators status", async () => {
        const group = await pool.connect(owner).selectGroup(5, seed)
        await pool.connect(owner).nonViewSelectGroup(5, seed)
        expect(group).to.deep.equal([
          bob.address,
          bob.address,
          bob.address,
          bob.address,
          bob.address,
        ])
      })
    })

    context("when group is very large", async () => {
      beforeEach(async () => {
        for (i = 101; i < 150; i++) {
          const address =
            "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + i.toString()
          await staking.setStake(address, minStake * i)
          await pool.connect(owner).insertOperator(address)
        }
      })

      it("should handle selection effectively", async () => {
        const group = await pool.connect(owner).selectGroup(100, seed)
        await pool.connect(owner).nonViewSelectGroup(100, seed)
        expect(group.length).to.be.equal(100)
      })
    })
  })
})
