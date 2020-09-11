const Branch = artifacts.require("Branch")
const Position = artifacts.require("Position")
const StackLib = artifacts.require("StackLib")
const Leaf = artifacts.require("Leaf")
const BondedSortitionPool = artifacts.require(
  "./contracts/BondedSortitionPool.sol",
)

const StakingContractStub = artifacts.require("StakingContractStub.sol")
const BondingContractStub = artifacts.require("BondingContractStub.sol")

const {mineBlocks} = require("./mineBlocks")

const {expectRevert} = require("@openzeppelin/test-helpers")

contract("BondedSortitionPool", (accounts) => {
  const seed = "0xff39d6cca87853892d2854566e883008bc"
  const bond = 100000000
  const poolWeightDivisor = web3.utils.toBN(10).pow(web3.utils.toBN(18))
  const minStake = web3.utils.toBN("100000").mul(poolWeightDivisor)
  const owner = accounts[9]
  let pool
  let bonding
  let staking
  let prepareOperator

  beforeEach(async () => {
    BondedSortitionPool.link(Branch)
    BondedSortitionPool.link(Position)
    BondedSortitionPool.link(StackLib)
    BondedSortitionPool.link(Leaf)
    staking = await StakingContractStub.new()
    bonding = await BondingContractStub.new()

    prepareOperator = async (address, weight) => {
      await bonding.setBondableValue(address, web3.utils.toBN("1000000000000000000000"))
      await staking.setStake(address, web3.utils.toBN(weight).mul(poolWeightDivisor))
      await pool.joinPool(address)
    }

    pool = await BondedSortitionPool.new(
      staking.address,
      bonding.address,
      minStake,
      bond,
      poolWeightDivisor,
      owner,
    )
  })

  describe("isOperatorInitialized", async () => {
    it("reverts if operator is not in the pool", async () => {
      const operator = accounts[0]

      expectRevert(
        pool.isOperatorInitialized(operator),
        "Operator is not in the pool",
      )
    })

    it("returns false when initialization period not passed", async () => {
      const operator = accounts[0]

      await prepareOperator(operator, 10)

      assert.isFalse(await pool.isOperatorInitialized(operator))

      assert.isFalse(
        await pool.isOperatorInitialized(operator),
        "incorrect result at the beginning of the period",
      )

      await mineBlocks(await pool.operatorInitBlocks())

      assert.isFalse(
        await pool.isOperatorInitialized(operator),
        "incorrect result when period almost passed",
      )
    })

    it("returns true when initialization period passed", async () => {
      const operator = accounts[0]
      await prepareOperator(operator, 10)

      await mineBlocks((await pool.operatorInitBlocks()).addn(1))

      assert.isTrue(await pool.isOperatorInitialized(operator))
    })
  })

  describe("selectSetGroup", async () => {
    it.only("returns different operators", async () => {
      await prepareOperator("0x036b011F4F00eF742613e9491f62bb3a7b897dF4", "4000000")
      await prepareOperator("0x0516c849a54d177FDA884864Ff8CAA480EF1Ef88", "4000000")
      await prepareOperator("0x0DBc6311099483D5be20b1F6598B4D33c676481A", "4000000")
      await prepareOperator("0x0edD6640017D1F82F2DfA0b9b5621fD062c3de53", "4000000")
      await prepareOperator("0x1325c54566A3E7c9948a42FC80aB884611497792", "4000000")
      await prepareOperator("0x1EfF077C326414c0aCb17d2A72A64DD3Be6121e0", "4000000")
      await prepareOperator("0x2116291fC3C49b3f8551dD87e13F423630CDcDC8", "4000000")
      await prepareOperator("0x265375963f921dcABf213F313E5E86523db1e29b", "4000000")
      await prepareOperator("0x290F15528be982954ba2ed6F8E6469B5c722f485", "4000000")
      await prepareOperator("0x2982e7Af4437F99dE0c7CEbe6D57a9D85d4ad871", "4000000")
      await prepareOperator("0x2ee15dD17aFEF8dBC8160eE109489115106BCbad", "4000000")
      await prepareOperator("0x30Cbc2382c45cE8592037f6E23eE41D869d3315C", "4000000")
      await prepareOperator("0x310E75F2C7A5A807498397Ce56D9806f6D1F9f39", "4000000")
      await prepareOperator("0x332fAeA07F8469B3e8F39d39AD68367c3A970133", "4000000")
      await prepareOperator("0x351BAe4Fd8CC298cc1d3520d7A3fa1e5F9b02D68", "4000000")
      await prepareOperator("0x39107ae6681EC988ceF8D7d38ca7c51Fd732e712", "4000000")
      await prepareOperator("0x3fd7DA817715c28996a27c068e13eAB839132Bd4", "4000000")
      await prepareOperator("0x422986373Ac12A5Cbb7eABc30D318ecC47b9058c", "4000000")
      await prepareOperator("0x42A72aC41d05B0105d50f5E69aE99DF9C5Bd46eA", "4000000")
      await prepareOperator("0x4438A8a521B23444926b6f897d7722c39626Bb36", "4000000")
      await prepareOperator("0x469FcD3C3373BdFbfAbAec94e9774fb5e17b3875", "4000000")
      await prepareOperator("0x47cBD9D77cc5bf8d466Ad75113ce8c7e69d7963F", "4000000")
      await prepareOperator("0x4A482e44BE06F9A6BF169b313Aae34e16fDa4f7C", "4000000")
      await prepareOperator("0x511657a1aF8AE849F91EE93836094ea26b08ECee", "4000000")
      await prepareOperator("0x512C7E69d6838EaeDC2cF1EEadD299a9a6a08CA6", "4000000")
      await prepareOperator("0x56A24F78D497C766cfFF3c7BBb5d8F211768254e", "4000000")
      await prepareOperator("0x56D5bff4e3ca9076a847471262CE15153A1A2A3F", "4000000")
      await prepareOperator("0x5958E34e08C23e0E09c24370b1f23A2F65FD7c5f", "4000000")
      await prepareOperator("0x5c91e34ee6e670548A10C05149DfBAEc86934085", "4000000")
      await prepareOperator("0x5cd805c6EbdD9E9881eEEC735bc6b88E53B30835", "4000000")
      await prepareOperator("0x5eb834d4a41A1D0346263d82f1E2c8311566dB2F", "4000000")
      await prepareOperator("0x637D91cdABB1119A4BEC0519CF3A66B1E7b65453", "4000000")
      await prepareOperator("0x6574f038ee32cB8a8d0AaEd8F7B124B36dA83E71", "4000000")
      await prepareOperator("0x686baAe0941cdd739857c8dbb32b130dca34d4Bf", "4000000")
      await prepareOperator("0x6BEc9423b5812f59013CA36c9d393EFbcd27Dfe9", "4000000")
      await prepareOperator("0x71F7dB13E9F4dB85D0f3c39A0E173ED98CfE2671", "4000000")
      await prepareOperator("0x7378CB9CD4271732eC259D45C145A7274e8517E6", "4000000")
      await prepareOperator("0x748444137e93Ef98977e5306AaDC295cF3e73E04", "4000000")
      await prepareOperator("0x7577EEB2cF0794C1796D2dc690024da854415363", "4000000")
      await prepareOperator("0x8283D4D86011a6e306dA540C7AB7e23228040aCf", "4000000")
      await prepareOperator("0x87a3f51c2720B1648d3746C667c94915ae882E88", "4000000")
      await prepareOperator("0x8a0013bF313768a310268a570Ac85f6Fc1868203", "4000000")
      await prepareOperator("0x8D3e0468bBb7103830bE0BA6C246c7618f8c4b3c", "4000000")
      await prepareOperator("0x8e1eE7aF9f7828238Da206c7a357FB7f5992a81E", "4000000")
      await prepareOperator("0x8EA8D5bA558D190E0d11bE6742EA730a4A9e7B49", "4000000")
      await prepareOperator("0x9528134Fd2d1A1258DDbaE3Cbd05c4B72f587c13", "4000000")
      await prepareOperator("0x989442eFF31506b66e093FA78A1b841913578021", "4000000")
      await prepareOperator("0x9A539Ecc0301e3650f54dccb067613FaC1F00806", "4000000")
      await prepareOperator("0x9BFb166E6565dc77432D57613820eECFFcEc75EC", "4000000")
      await prepareOperator("0x9C006fd45b99A162e49bD653ce71bca100217C30", "4000000")
      await prepareOperator("0x9e8F5520a8dAe3a854d19FD02B9a55818B226C09", "4000000")
      await prepareOperator("0xA67230f0ee82b66F819C98930c3368557C5C94Ad", "4000000")
      await prepareOperator("0xAd1B399C73fEcfd9c58bCcdc5DD92bF945B57D09", "4000000")
      await prepareOperator("0xAf04933a1a1f773Dd606D959457dB57347d3810C", "4000000")
      await prepareOperator("0xB07f8756171aDB0644F97c88cf4f23C0bB010292", "4000000")
      await prepareOperator("0xB1Fe0ba4c79166e5Ef17F1B4620b87f19Dc2B77C", "4000000")
      await prepareOperator("0xB349B735A35A4Ba42B004222d73B3da410cf94d7", "4000000")
      await prepareOperator("0xB3E63E0Ab8Db3cC06Be642017463C13d2A0577FB", "4000000")
      await prepareOperator("0xB512a3AC0adb4F5e30700a277991D68166c165F0", "4000000")
      await prepareOperator("0xb734E9CEBF12Ac1B64D3f90a97FA04BFe0044FDb", "4000000")
      await prepareOperator("0xB9642b1a4AEa1F6a5D9f3dc21c0AF69189526fb8", "4000000")
      await prepareOperator("0xba58576718d6EFF82CfbC30874380563BC4d650E", "4000000")
      await prepareOperator("0xBe829f3DEef84Ed30287Cae75e2AE70df2c9B7a8", "4000000")
      await prepareOperator("0xbF143850a6B4Fd1D6c4C96091Bf179403cF1fBA9", "4000000")
      await prepareOperator("0xc23ABF54f2823Fee889CB28D10ed1a955f340c7D", "4000000")
      await prepareOperator("0xc87a0b29C755C02edecEcB3445C3EeA3fDA4422d", "4000000")
      await prepareOperator("0xcDC329C4c54ceC94530e73dF93d6a04B6D39550F", "4000000")
      await prepareOperator("0xcEC69a9A7D1cd21Ce5f75e72196b5175D975c618", "4000000")
      await prepareOperator("0xcfaaBaaf161a9C4328F9892b6BeD753BA4BFa48a", "4000000")
      await prepareOperator("0xd0D7387CBA663b591da5cD754249a157278e4625", "4000000")
      await prepareOperator("0xD1DcFFC6498001427a3872198849867eba69474B", "4000000")
      await prepareOperator("0xd472909B47925e78Cc3Cc4530155E00a2899e4B2", "4000000")
      await prepareOperator("0xd4AD6CC857AD1da3b4313d722C7F3C9DBF41b6e2", "4000000")
      await prepareOperator("0xd51B633eA05B5DAA88401F3C8F9825Da2Fbe3A85", "4000000")
      await prepareOperator("0xD63228C6DA563B80D201b9Cb4C1058b783098584", "4000000")
      await prepareOperator("0xD914283e872677BF650EfC63629da469c6e9FC03", "4000000")
      await prepareOperator("0xd94A4D1f7125e490D3cfEd41446843d6521235d8", "4000000")
      await prepareOperator("0xDBDcBF36259666C5CaED53a7eA9BdF67805d69b5", "4000000")
      await prepareOperator("0xDFc2c1E31998037b2B292a692d7eAB82f02e1Ff6", "4000000")
      await prepareOperator("0xE3122D41b29A0f36d7C27FE57dbAe62C89827A05", "4000000")
      await prepareOperator("0xe34E00FE00bC908a96BC53577D30F47e5602666f", "4000000")
      await prepareOperator("0xE74Aa33b3820b4cfE278B24B40643442040491e7", "4000000")
      await prepareOperator("0xeAcDfd67aAfBCfd0557A6ff18A640024f36Cb299", "4000000")
      await prepareOperator("0xeAf250cc31207e22E11B8e6bb009837B3b895D77", "4000000")
      await prepareOperator("0xeb8Fe404550b48499fc5aFC6334fa02DB0461Dd8", "4000000")
      await prepareOperator("0xEc485D2d460b204C380a8De104dEDA7c4db820AA", "4000000")
      await prepareOperator("0xec6E5988413cd060C5418c973c14934e2B7b7A64", "4000000")
      await prepareOperator("0xee29404e41ECef6f3AF41bb734E9583FF9Ad3ED5", "4000000")
      await prepareOperator("0xEEC090eC5D0eF5602a21517F76715A4BBF129f68", "4000000")
      await prepareOperator("0xeF97A005e6A5A78314ceE5E2c9C6350257274f25", "4000000")
      await prepareOperator("0xf10Fc92C4a7c88A6B665B9601c95a9132841523e", "4000000")
      await prepareOperator("0xF2D42bB9C4ed44084aa2C0c04f0A7b66071857AE", "4000000")
      await prepareOperator("0xf341A912F3CA77e73a49859dabB23e1D200A0048", "4000000")
      await prepareOperator("0xf3B37721ceC9123F44aBfa437fD4f4DD45d4ffd8", "4000000")
      await prepareOperator("0xF465FcfC7537421A6e4b14A8A7F2A2dCC370Eff9", "4000000")
      await prepareOperator("0xfa7dbFA0e2F60CAf1DE345e1DEB8A0c872187674", "4000000")
      await prepareOperator("0xfbA063C3045201E8260E73ceF3c25C8D8Da1D84a", "4000000")
      await prepareOperator("0xFbc885A1af1ee74F191369312F544796ABaE9477", "4000000")
      await prepareOperator("0xFDeFAAe55DA393011acfB2387bDd6AEe029153F4", "4000000")
      await prepareOperator("0xfF507D89ee8781583E44c5b1aC2Da65F21d7FCf9", "4000000")

      await mineBlocks(11)

      const operatorsInPool = await pool.operatorsInPool()
      console.log(`operators in pool: ${operatorsInPool}`)
   
      const totalWeight = await pool.totalWeight()
      console.log(`total weight: ${totalWeight}`)

      let group
  
      let beaconSeed = web3.utils.numberToHex("102164561645464621572619913075106729285750952667175771024679150890446416239732")
      group = await pool.selectSetGroup.call(3, beaconSeed, minStake, bond, {
        from: owner,
      })
      console.log(group)


      beaconSeed = web3.utils.numberToHex("10508619977257066818146419264725173133749180236113458073982425592827879696458")
      group = await pool.selectSetGroup.call(3, beaconSeed, minStake, bond, {
        from: owner,
      })
      console.log(group)
    })

    it("returns group of expected size with unique members", async () => {
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 11)
      await prepareOperator(accounts[2], 12)
      await prepareOperator(accounts[3], 5)
      await prepareOperator(accounts[4], 1)

      await mineBlocks(11)

      let group

      group = await pool.selectSetGroup.call(3, seed, minStake, bond, {
        from: owner,
      })
      await pool.selectSetGroup(3, seed, minStake, bond, {from: owner})
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      group = await pool.selectSetGroup.call(5, seed, minStake, bond, {
        from: owner,
      })
      await pool.selectSetGroup(5, seed, minStake, bond, {from: owner})
      assert.equal(group.length, 5)
      assert.isFalse(hasDuplicates(group))
    })

    function hasDuplicates(array) {
      return new Set(array).size !== array.length
    }

    it("reverts when called by non-owner", async () => {
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 11)
      await prepareOperator(accounts[2], 12)

      await mineBlocks(11)

      try {
        await pool.selectSetGroup(3, seed, minStake, bond, {from: accounts[0]})
      } catch (error) {
        assert.include(error.message, "Only owner may select groups")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("reverts when there are no operators in pool", async () => {
      try {
        await pool.selectSetGroup(3, seed, minStake, bond, {from: owner})
      } catch (error) {
        assert.include(error.message, "Not enough operators in pool")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("reverts when there are not enough operators in pool", async () => {
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 11)

      await mineBlocks(11)

      try {
        await pool.selectSetGroup(3, seed, minStake, bond, {from: owner})
      } catch (error) {
        assert.include(error.message, "Not enough operators in pool")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("removes stake-ineligible operators and still works afterwards", async () => {
      await prepareOperator(accounts[0], 2)
      await prepareOperator(accounts[1], 2)
      await prepareOperator(accounts[2], 200)
      await prepareOperator(accounts[3], 2)

      await mineBlocks(11)

      await staking.setStake(accounts[2], 1 * minStake)

      // all 4 operators in the pool
      assert.equal(await pool.operatorsInPool(), 4)

      // should select group and remove accounts[2]
      await pool.selectSetGroup(3, seed, 2 * minStake, bond, {from: owner})

      // should have only 3 operators in the pool now
      group = await pool.selectSetGroup.call(3, seed, minStake, bond, {
        from: owner,
      })

      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))
      assert.equal(await pool.operatorsInPool(), 3) // accounts[2] removed
    })

    it("removes minimum-bond-ineligible operators and still works afterwards", async () => {
      await prepareOperator(accounts[0], 2)
      await prepareOperator(accounts[1], 200)
      await prepareOperator(accounts[2], 2)
      await prepareOperator(accounts[3], 2)

      await mineBlocks(11)

      await pool.setMinimumBondableValue(2 * bond, {from: owner})
      await bonding.setBondableValue(accounts[1], 1 * bond)

      // all 4 operators in the pool
      assert.equal(await pool.operatorsInPool(), 4)

      // should select group and remove accounts[1]
      await pool.selectSetGroup(3, seed, minStake, 2 * bond, {from: owner})

      // should have only 3 operators in the pool now
      group = await pool.selectSetGroup.call(3, seed, minStake, bond, {
        from: owner,
      })

      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))
      assert.equal(await pool.operatorsInPool(), 3) // accounts[1] removed
    })

    it("skips selection-bond-ineligible operators and still works afterwards", async () => {
      await prepareOperator(accounts[0], 2)
      await prepareOperator(accounts[1], 200)
      await prepareOperator(accounts[2], 2)
      await prepareOperator(accounts[3], 2)

      await mineBlocks(11)

      await pool.setMinimumBondableValue(1 * bond, {from: owner})
      await bonding.setBondableValue(accounts[1], 1 * bond)

      // all 4 operators in the pool
      assert.equal(await pool.operatorsInPool(), 4)

      // should select group and skip accounts[1] (do not remove it!)
      await pool.selectSetGroup(3, seed, minStake, 2 * bond, {from: owner})

      // should still have 4 operators in the pool
      group = await pool.selectSetGroup.call(3, seed, minStake, bond, {
        from: owner,
      })

      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))
      assert.equal(await pool.operatorsInPool(), 4)
    })

    it("doesn't mind operators whose weight has increased", async () => {
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 11)
      await prepareOperator(accounts[2], 12)

      await mineBlocks(11)

      await staking.setStake(accounts[2], 15 * minStake)

      group = await pool.selectSetGroup.call(3, seed, minStake, bond, {
        from: owner,
      })
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))
    })

    it("can handle removing multiple outdated operators", async () => {
      await prepareOperator(accounts[0], 70)
      await prepareOperator(accounts[1], 11)
      await prepareOperator(accounts[2], 12)
      await prepareOperator(accounts[3], 5)
      await prepareOperator(accounts[4], 2)
      await prepareOperator(accounts[5], 1)
      await prepareOperator(accounts[6], 8)
      await prepareOperator(accounts[7], 50)
      await prepareOperator(accounts[8], 3)
      await prepareOperator(accounts[9], 42)

      await mineBlocks(11)

      await staking.setStake(accounts[0], 1 * minStake)
      await staking.setStake(accounts[1], 1 * minStake)
      await staking.setStake(accounts[2], 1 * minStake)
      await staking.setStake(accounts[4], 1 * minStake)
      await staking.setStake(accounts[6], 7 * minStake)
      await staking.setStake(accounts[7], 1 * minStake)
      await staking.setStake(accounts[9], 1 * minStake)

      group = await pool.selectSetGroup.call(3, seed, minStake, bond, {
        from: owner,
      })
      await pool.selectSetGroup(3, seed, minStake, bond, {from: owner})
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      try {
        await pool.selectSetGroup(4, seed, minStake, bond, {from: owner})
      } catch (error) {
        assert.include(error.message, "Not enough operators in pool")
        return
      }

      assert.fail("Expected throw not received")
    })

    it("behaves reasonably with loads of operators", async () => {
      await prepareOperator(accounts[0], 1)
      await prepareOperator(accounts[1], 1)
      await prepareOperator(accounts[2], 1)
      await prepareOperator(accounts[3], 1)
      await prepareOperator(accounts[4], 1)
      await prepareOperator(accounts[5], 1)
      await prepareOperator(accounts[6], 1)
      await prepareOperator(accounts[7], 1)
      await prepareOperator(accounts[8], 1)
      await prepareOperator(accounts[9], 1)

      await mineBlocks(11)

      group = await pool.selectSetGroup.call(3, seed, minStake, bond, {
        from: owner,
      })
      await pool.selectSetGroup(3, seed, minStake, bond, {from: owner})
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))
    })

    it("ignores too recently added operators", async () => {
      await prepareOperator(accounts[0], 1)
      await prepareOperator(accounts[1], 1)
      await prepareOperator(accounts[2], 1)
      await prepareOperator(accounts[3], 1)
      await prepareOperator(accounts[4], 1)
      // no accounts[5] here
      await prepareOperator(accounts[6], 1)
      await prepareOperator(accounts[7], 1)
      await prepareOperator(accounts[8], 1)
      await prepareOperator(accounts[9], 1)

      await mineBlocks(11)

      await prepareOperator(accounts[5], 1)

      await mineBlocks(10)

      group = await pool.selectSetGroup.call(9, seed, minStake, bond, {
        from: owner,
      })
      await pool.selectSetGroup(9, seed, minStake, bond, {from: owner})

      assert.equal(group.length, 9)
      assert.isFalse(hasDuplicates(group))
      assert.isFalse(group.includes(accounts[5]))
    })

    it("updates the bond value", async () => {
      await prepareOperator(accounts[0], 10)
      await prepareOperator(accounts[1], 21)
      await prepareOperator(accounts[2], 32)

      await mineBlocks(11)

      group = await pool.selectSetGroup.call(3, seed, minStake, bond * 10, {
        from: owner,
      })
      await pool.selectSetGroup(3, seed, minStake, bond * 10, {from: owner})
      assert.equal(group.length, 3)
      assert.isFalse(hasDuplicates(group))

      group = await pool.selectSetGroup.call(2, seed, minStake, bond * 20, {
        from: owner,
      })
      await pool.selectSetGroup(2, seed, minStake, bond * 20, {from: owner})
      assert.equal(group.length, 2)
      assert.isFalse(hasDuplicates(group))

      try {
        await pool.selectSetGroup(3, seed, minStake, bond * 20, {from: owner})
      } catch (error) {
        assert.include(error.message, "Not enough operators in pool")
        return
      }

      assert.fail("Expected throw not received")
    })
  })

  describe("setMinimumBondableValue", async () => {
    it("can only be called by the owner", async () => {
      try {
        await pool.setMinimumBondableValue(1, {from: accounts[0]})
        assert.fail("Expected throw not received")
      } catch (error) {
        assert.include(
          error.message,
          "Only owner may update minimum bond value",
        )
      }
    })

    it("updates the minimum bondable value", async () => {
      await pool.setMinimumBondableValue(1, {from: owner})
      assert.equal(await pool.getMinimumBondableValue(), 1)

      await pool.setMinimumBondableValue(6, {from: owner})
      assert.equal(await pool.getMinimumBondableValue(), 6)
    })
  })
})
