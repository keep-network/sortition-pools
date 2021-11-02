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

  describe("selectGroup", async () => {
    context("when called by owner", () => {
      beforeEach(async () => {
        await staking.setStake(alice.address, 20000)
        await staking.setStake(bob.address, 22000)
        await staking.setStake(carol.address, 24000)
        await pool.joinPool(alice.address)
        await pool.joinPool(bob.address)
        await pool.joinPool(carol.address)
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
        await pool.joinPool(alice.address)
        await pool.joinPool(bob.address)
        await pool.joinPool(carol.address)
      })

      it("should revert", async () => {
        await expect(
          pool.connect(alice).selectGroup(3, seed),
        ).to.be.revertedWith("Only owner may select groups")
      })
    })

    context("reverts when there are no operators in pool", async () => {
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
          await pool.joinPool(alice.address)
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
        await pool.joinPool(alice.address)
        await pool.joinPool(bob.address)

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
        await pool.joinPool(alice.address)
        await pool.joinPool(bob.address)

        await staking.setStake(bob.address, 390000)
      })

      it("should not remove the operator", async () => {
        const group = await pool.connect(owner).selectGroup(5, seed)
        await pool.connect(owner).nonViewSelectGroup(5, seed)
        expect(group.length).to.be.equal(5)
      })
    })

    context("when outdated operators update their status", (async) => {
      beforeEach(async () => {
        await staking.setStake(alice.address, 2000)
        await staking.setStake(bob.address, 4000000)
        await pool.joinPool(alice.address)
        await pool.joinPool(bob.address)

        await staking.setStake(bob.address, 390000)
        await staking.setStake(alice.address, 1000)

        await helpers.time.mineBlocks(11)

        await pool.updateOperatorStatus(bob.address)
        await pool.updateOperatorStatus(alice.address)
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
          await pool.joinPool(address)
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
