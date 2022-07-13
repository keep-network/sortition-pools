const chai = require("chai")
const expect = chai.expect
const { ethers, helpers } = require("hardhat")

describe("SortitionPool", () => {
  const seed =
    "0xff39d6cca87853892d2854566e883008bc000000000000000000000000000000"
  const poolWeightDivisor = 2000

  let token
  let pool

  let deployer
  let owner
  let alice
  let bob
  let carol
  let aliceBeneficiary
  let bobBeneficiary

  beforeEach(async () => {
    ;[deployer, owner, alice, bob, carol, aliceBeneficiary, bobBeneficiary] =
      await ethers.getSigners()

    const TokenStub = await ethers.getContractFactory("TokenStub")
    token = await TokenStub.deploy()
    await token.deployed()

    const SortitionPool = await ethers.getContractFactory("SortitionPool")
    pool = await SortitionPool.deploy(token.address, poolWeightDivisor)
    await pool.deployed()

    await pool.connect(deployer).transferOwnership(owner.address)
  })

  describe("lock", () => {
    context("when called by the owner", () => {
      beforeEach(async () => {
        // Pool is unlocked by default.
        await pool.connect(owner).lock()
      })

      it("should lock the pool", async () => {
        expect(await pool.isLocked()).to.be.true
      })
    })

    context("when called by a non-owner", () => {
      it("should revert", async () => {
        await expect(pool.connect(alice).lock()).to.be.revertedWith(
          "Ownable: caller is not the owner",
        )
      })
    })
  })

  describe("unlock", () => {
    beforeEach(async () => {
      // Pool is unlocked by default so we need to lock it explicitly.
      await pool.connect(owner).lock()
    })

    context("when called by the owner", () => {
      beforeEach(async () => {
        await pool.connect(owner).unlock()
      })

      it("should unlock the pool", async () => {
        expect(await pool.isLocked()).to.be.false
      })
    })

    context("when called by a non-owner", () => {
      it("should revert", async () => {
        await expect(pool.connect(alice).unlock()).to.be.revertedWith(
          "Ownable: caller is not the owner",
        )
      })
    })
  })

  describe("insertOperator", () => {
    context("when sortition pool is unlocked", () => {
      context("when called by the owner", () => {
        context("when operator is eligible", () => {
          beforeEach(async () => {
            await pool
              .connect(owner)
              .insertOperator(alice.address, poolWeightDivisor)
          })

          it("should insert the operator to the pool", async () => {
            expect(await pool.isOperatorInPool(alice.address)).to.be.true
          })
        })

        context("when operator is not eligible", () => {
          it("should revert", async () => {
            await expect(
              pool
                .connect(owner)
                .insertOperator(alice.address, poolWeightDivisor - 1),
            ).to.be.revertedWith("Operator not eligible")
          })
        })
      })

      context("when called by a non-owner", () => {
        it("should revert", async () => {
          await expect(
            pool
              .connect(alice)
              .insertOperator(alice.address, poolWeightDivisor),
          ).to.be.revertedWith("Ownable: caller is not the owner")
        })
      })
    })

    context("when sortition pool is locked", () => {
      beforeEach(async () => {
        await pool.connect(owner).lock()
      })

      it("should revert", async () => {
        await expect(
          pool.connect(owner).insertOperator(alice.address, 20000),
        ).to.be.revertedWith("Sortition pool locked")
      })
    })
  })

  describe("updateOperatorStatus", () => {
    beforeEach(async () => {
      await pool.connect(owner).insertOperator(alice.address, 2000)
    })

    context("when sortition pool is unlocked", () => {
      context("when called by the owner", () => {
        context("when operator is still eligible", () => {
          beforeEach(async () => {
            await pool.connect(owner).updateOperatorStatus(alice.address, 5000)
          })

          it("should update operator status", async () => {
            expect(await pool.isOperatorUpToDate(alice.address, 2000)).to.be
              .false
            expect(await pool.isOperatorUpToDate(alice.address, 5000)).to.be
              .true
          })
        })

        context("when operator is no longer eligible", () => {
          beforeEach(async () => {
            await pool
              .connect(owner)
              .updateOperatorStatus(alice.address, poolWeightDivisor - 1)
          })

          it("should remove operator from the pool", async () => {
            expect(await pool.isOperatorInPool(alice.address)).to.be.false
          })
        })
      })

      context("when called by a non-owner", () => {
        it("should revert", async () => {
          await expect(
            pool.connect(alice).updateOperatorStatus(alice.address, 10000),
          ).to.be.revertedWith("Ownable: caller is not the owner")
        })
      })
    })

    context("when sortition pool is locked", () => {
      beforeEach(async () => {
        await pool.connect(owner).lock()
      })

      it("should revert", async () => {
        await expect(
          pool.connect(owner).updateOperatorStatus(alice.address, 10000),
        ).to.be.revertedWith("Sortition pool locked")
      })
    })
  })

  describe("selectGroup", async () => {
    context("when sortition pool is locked", () => {
      beforeEach(async () => {})

      context("when there is enough operators in pool", () => {
        beforeEach(async () => {
          await pool.connect(owner).insertOperator(alice.address, 20000)
          await pool.connect(owner).insertOperator(bob.address, 22000)
          await pool.connect(owner).insertOperator(carol.address, 24000)
          await pool.connect(owner).lock()
        })

        it("should return group of expected size", async () => {
          const group = await pool.connect(owner).selectGroup(3, seed)
          await pool.connect(owner).selectGroup(3, seed)
          expect(group.length).to.be.equal(3)
        })
      })

      context("when there are no operators in the pool", async () => {
        it("should revert", async () => {
          await pool.connect(owner).lock()
          await expect(
            pool.connect(owner).selectGroup(3, seed),
          ).to.be.revertedWith("Not enough operators in pool")
        })
      })

      context(
        "when the number of operators is less than selected group size",
        async () => {
          beforeEach(async () => {
            await pool.connect(owner).insertOperator(alice.address, 2000)
            await pool.connect(owner).lock()
          })

          it("should return group of expected size", async () => {
            const group = await pool.connect(owner).selectGroup(5, seed)
            await pool.connect(owner).selectGroup(5, seed)
            expect(group.length).to.be.equal(5)
          })
        },
      )

      context("when group is very large", async () => {
        beforeEach(async () => {
          for (i = 101; i < 150; i++) {
            const address =
              "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + i.toString()
            await pool.connect(owner).insertOperator(address, 2000 * i)
          }
          await pool.connect(owner).lock()
        })

        it("should handle selection effectively", async () => {
          const group = await pool.connect(owner).selectGroup(100, seed)
          await pool.connect(owner).selectGroup(100, seed)
          expect(group.length).to.be.equal(100)
        })
      })
    })

    context("when sortition pool is unlocked", () => {
      it("should revert", async () => {
        await pool.connect(owner).insertOperator(alice.address, 20000)
        await pool.connect(owner).insertOperator(bob.address, 22000)
        await pool.connect(owner).insertOperator(carol.address, 24000)
        await expect(
          pool.connect(owner).selectGroup(3, seed),
        ).to.be.revertedWith("Sortition pool unlocked")
      })
    })
  })

  describe("pool rewards", async () => {
    async function withdrawRewards(
      pool,
      owner,
      operatorAddress,
      beneficiaryAddress,
    ) {
      const amount = await pool
        .connect(owner)
        .callStatic.withdrawRewards(operatorAddress, beneficiaryAddress)
      await pool
        .connect(owner)
        .withdrawRewards(operatorAddress, beneficiaryAddress)
      return amount
    }

    it("can only be withdrawn by the owner", async () => {
      await expect(
        withdrawRewards(pool, bob, bob.address, bobBeneficiary.address),
      ).to.be.revertedWith("Ownable: caller is not the owner")
    })

    it("pays rewards correctly", async () => {
      await token.connect(deployer).mint(deployer.address, 1000)
      await pool.connect(owner).insertOperator(alice.address, 10000)
      await pool.connect(owner).insertOperator(bob.address, 20000)
      await token.connect(deployer).approveAndCall(pool.address, 300, [])

      const aliceExpectedReward = 100
      const bobExpectedReward = 200

      const aliceReward = await withdrawRewards(
        pool,
        owner,
        alice.address,
        aliceBeneficiary.address,
      )
      const bobReward = await withdrawRewards(
        pool,
        owner,
        bob.address,
        bobBeneficiary.address,
      )
      expect(aliceReward).to.equal(aliceExpectedReward)
      expect(bobReward).to.equal(bobExpectedReward)

      const aliceBalance = await token.balanceOf(aliceBeneficiary.address)
      const bobBalance = await token.balanceOf(bobBeneficiary.address)
      expect(aliceBalance).to.equal(aliceExpectedReward)
      expect(bobBalance).to.equal(bobExpectedReward)
    })

    it("handles new and returning operators correctly", async () => {
      await token.connect(deployer).mint(deployer.address, 1000)
      await pool.connect(owner).insertOperator(alice.address, 10000)
      await token.connect(deployer).approveAndCall(pool.address, 300, [])
      await pool.connect(owner).insertOperator(bob.address, 20000)
      await pool.connect(owner).updateOperatorStatus(alice.address, 0)
      await token.connect(deployer).approveAndCall(pool.address, 300, [])
      await pool.connect(owner).insertOperator(alice.address, 10000)
      await token.connect(deployer).approveAndCall(pool.address, 300, [])
      const aliceExpectedReward = 400
      const bobExpectedReward = 500

      const aliceReward = await withdrawRewards(
        pool,
        owner,
        alice.address,
        aliceBeneficiary.address,
      )
      const bobReward = await withdrawRewards(
        pool,
        owner,
        bob.address,
        bobBeneficiary.address,
      )
      expect(aliceReward).to.equal(aliceExpectedReward)
      expect(bobReward).to.equal(bobExpectedReward)

      const aliceBalance = await token.balanceOf(aliceBeneficiary.address)
      const bobBalance = await token.balanceOf(bobBeneficiary.address)
      expect(aliceBalance).to.equal(aliceExpectedReward)
      expect(bobBalance).to.equal(bobExpectedReward)
    })

    it("doesn't pay to ineligible operators", async () => {
      await token.connect(deployer).mint(deployer.address, 1000)
      await pool.connect(owner).insertOperator(alice.address, 10000)
      await pool.connect(owner).insertOperator(bob.address, 20000)
      const now = await helpers.time.lastBlockTime()
      const bobID = await pool.getOperatorID(bob.address)
      await pool.connect(owner).setRewardIneligibility([bobID], now + 100)
      await token.connect(deployer).approveAndCall(pool.address, 300, [])
      const aliceExpectedReward = 100
      const bobExpectedReward = 0

      const aliceReward = await withdrawRewards(
        pool,
        owner,
        alice.address,
        aliceBeneficiary.address,
      )
      const bobReward = await withdrawRewards(
        pool,
        owner,
        bob.address,
        bobBeneficiary.address,
      )
      expect(aliceReward).to.equal(aliceExpectedReward)
      expect(bobReward).to.equal(bobExpectedReward)

      await pool.connect(owner).withdrawIneligible(carol.address)
      const aliceBalance = await token.balanceOf(aliceBeneficiary.address)
      const bobBalance = await token.balanceOf(bobBeneficiary.address)
      const ineligibleReward = await token.balanceOf(carol.address)
      expect(aliceBalance).to.equal(aliceExpectedReward)
      expect(bobBalance).to.equal(bobExpectedReward)
      expect(ineligibleReward).to.equal(200)
    })

    it("sets and restores operator eligibility correctly", async () => {
      await token.connect(deployer).mint(deployer.address, 1000)
      await pool.connect(owner).insertOperator(alice.address, 10000)
      await pool.connect(owner).insertOperator(bob.address, 20000)

      const now = await helpers.time.lastBlockTime()
      const bobID = await pool.getOperatorID(bob.address)

      await pool.connect(owner).setRewardIneligibility([bobID], now + 100)

      expect(await pool.isEligibleForRewards(bob.address)).to.be.false
      expect(await pool.isEligibleForRewards(alice.address)).to.be.true

      expect(await pool.canRestoreRewardEligibility(bob.address)).to.be.false
      expect(await pool.rewardsEligibilityRestorableAt(bob.address)).to.equal(
        now + 100,
      )

      await expect(
        pool.restoreRewardEligibility(bob.address),
      ).to.be.revertedWith("Operator still ineligible")

      // Ineligibility is set for a duration. Bob was ineligible for 100
      // seconds, so we move forward 101 seconds to allow us to make him
      // eligible again.
      await helpers.time.increaseTime(101)

      expect(await pool.canRestoreRewardEligibility(bob.address)).to.be.true
      await pool.restoreRewardEligibility(bob.address)
      expect(await pool.isEligibleForRewards(bob.address)).to.be.true
    })

    it("can set many operators ineligible", async () => {
      const evens = []
      for (i = 101; i < 150; i++) {
        const address = "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + i.toString()
        await pool.connect(owner).insertOperator(address, 2000 * i)
        if (i % 2 == 0) {
          const id = await pool.getOperatorID(address)
          evens.push(id)
        }
      }
      await pool.connect(owner).lock()

      const now = await helpers.time.lastBlockTime()
      await pool.connect(owner).setRewardIneligibility(evens, now + 100)

      const group = await pool.selectGroup(100, seed)
      expect(group.length).to.equal(100)
    })
  })
})
