const {accounts, contract, web3} = require("@openzeppelin/test-environment")

const Branch = contract.fromArtifact("Branch")
const Position = contract.fromArtifact("Position")
const StackLib = contract.fromArtifact("StackLib")
const Leaf = contract.fromArtifact("Leaf")
const BondedSortitionPool = contract.fromArtifact("BondedSortitionPool")
const FullyBackedSortitionPool = contract.fromArtifact(
  "FullyBackedSortitionPool",
)

const StakingContractStub = contract.fromArtifact("StakingContractStub")
const BondingContractStub = contract.fromArtifact("BondingContractStub")

const {mineBlocks} = require("./helpers/mineBlocks")
const {createSnapshot, restoreSnapshot} = require("./helpers/snapshot")

const chai = require("chai")
const assert = chai.assert

const initialSeed =
  "0xe1df17bc605ccc488fc59e3a69f8101a36094a4d250dd48b5d730c50d6dfdc74"
const groupSize = 3

const tokenDecimalMultiplier = web3.utils.toBN(10).pow(web3.utils.toBN(18)) // 1e18
const poolWeightDivisor = web3.utils.toBN(10).pow(web3.utils.toBN(18)) // 1e18

// Takes the `operators` array and the array of all `selectionResults` and
// reduces it into a mapping between the operator and the number of how many
// times the operator has been selected. If the operator has never been selected
// and is not in `selectionResults` array, the number of selections is 0.
function reduceResults(operators, selectionResults) {
  const accumulator = {}
  operators.forEach((operator) => (accumulator[operator] = 0))

  return selectionResults.reduce((_, operator) => {
    accumulator[operator] += 1
    return accumulator
  }, accumulator)
}

describe("BondedSortitionPool", () => {
  const owner = accounts[0]

  const minimumStake = web3.utils.toBN("10000").mul(tokenDecimalMultiplier) // 10k KEEP
  const minimumBondableValue = web3.utils.toBN("20").mul(tokenDecimalMultiplier) // 20 ETH

  let keepBonding
  let keepStaking
  let pool

  let operators

  before(async () => {
    await BondedSortitionPool.detectNetwork()
    await BondedSortitionPool.link("Branch", (await Branch.new()).address)
    await BondedSortitionPool.link("Position", (await Position.new()).address)
    await BondedSortitionPool.link("StackLib", (await StackLib.new()).address)
    await BondedSortitionPool.link("Leaf", (await Leaf.new()).address)

    keepStaking = await StakingContractStub.new()
    keepBonding = await BondingContractStub.new()

    pool = await BondedSortitionPool.new(
      keepStaking.address,
      keepBonding.address,
      minimumStake,
      minimumBondableValue,
      poolWeightDivisor,
      owner,
    )

    operators = []
    for (let i = 0; i < 100; i++) {
      operators.push(web3.eth.accounts.create().address)
    }
  })

  beforeEach(async () => {
    await createSnapshot()
  })

  afterEach(async () => {
    await restoreSnapshot()
  })

  describe("selectSetGroup result distribution", async () => {
    it("is similar between operators with the same stake", async () => {
      await prepareOperator(operators[0], "1000000", "10000") // 1M KEEP, 10k ETH
      await prepareOperator(operators[1], "1000000", "500") // 1M KEEP, 500 ETH
      await prepareOperator(operators[2], "1000000", "100") // 1M KEEP, 100 ETH
      await prepareOperator(operators[3], "1000000", "100") // 1M KEEP, 50 ETH
      await prepareOperator(operators[4], "1000000", "100") // 1M KEEP, 40 ETH

      const operatorsInPool = operators.slice(0, 5)

      await mineBlocks(11)

      const allSelections = await runSelections(200)
      const stats = reduceResults(operatorsInPool, allSelections)

      // We have 5 operators with the same stake and we are running the
      // selection 200 times. Given that the order does not matter and no
      // repetitions are allowed, each operator should be selected at least
      // 100 times.
      for (const operator of operatorsInPool) {
        if (stats[operator] == 0) {
          assert.fail(`operator ${operator} has never been selected`)
        }
        if (stats[operator] < 100) {
          assert.fail(
            `operator ${operator} should be selected at least 100 times`,
          )
        }
      }
    })

    it("promotes operators with higher stake", async () => {
      for (let i = 0; i < 25; i++) {
        await prepareOperator(operators[i], "1000000", "1000") // 1M KEEP, 1k ETH
      }
      for (let i = 25; i < 50; i++) {
        await prepareOperator(operators[i], "500000", "1000") // 500k KEEP, 1k ETH
      }
      for (let i = 50; i < 75; i++) {
        await prepareOperator(operators[i], "250000", "1000") // 250k KEEP, 1k ETH
      }
      for (let i = 75; i < 100; i++) {
        await prepareOperator(operators[i], "50000", "1000") // 50k KEEP, 1k ETH
      }

      await mineBlocks(11)

      const allSelections = await runSelections(2500)
      const stats = reduceResults(operators, allSelections)

      await assertSelectedMoreOftenThan(
        operators.slice(0, 25),
        operators.slice(25, 50),
        stats,
      )
      await assertSelectedMoreOftenThan(
        operators.slice(25, 50),
        operators.slice(50, 75),
        stats,
      )
      await assertSelectedMoreOftenThan(
        operators.slice(50, 75),
        operators.slice(75, 100),
        stats,
      )
    })
  })

  async function prepareOperator(address, stake, bond) {
    await keepStaking.setStake(
      address,
      web3.utils.toBN(stake).mul(tokenDecimalMultiplier),
    )
    await keepBonding.setBondableValue(
      address,
      web3.utils.toBN(bond).mul(tokenDecimalMultiplier),
    )
    await pool.joinPool(address)
  }

  // Runs the selectSetGroup `times` times and returns concatenated results
  // of all selections.
  async function runSelections(times) {
    let allSelections = []
    let seed = initialSeed

    for (let i = 0; i < times; i++) {
      const group = await pool.selectSetGroup.call(
        groupSize,
        seed,
        minimumStake,
        minimumBondableValue,
        {from: owner},
      )

      await pool.selectSetGroup.call(
        groupSize,
        seed,
        minimumStake,
        minimumBondableValue,
        {from: owner},
      )

      allSelections = allSelections.concat(group)
      seed = web3.utils.soliditySha3(seed)
    }

    return allSelections
  }

  // Asserts whether all operators from `operators` array has been selected more
  // times than all operators from `thanOperators` array. If not, fails the test.
  async function assertSelectedMoreOftenThan(operators, thanOperators, stats) {
    for (operator of operators) {
      for (anotherOperator of thanOperators) {
        if (stats[operator] <= stats[anotherOperator]) {
          const info = await operatorInfo(operator)
          const anotherInfo = await operatorInfo(anotherOperator)

          assert.fail(
            `operator ${operator} with stake ${info.stake} KEEP ` +
              `and unbonded value ${info.bond} ETH ` +
              `was selected ${stats[operator]} times while ` +
              `operator ${anotherOperator} with stake ${anotherInfo.stake} KEEP ` +
              `and unbonded value ${anotherInfo.bond} ETH ` +
              `was selected ${stats[anotherOperator]} times`,
          )
        }
      }
    }
  }

  async function operatorInfo(operator) {
    const stake = await keepStaking.stakedTokens(operator)
    const bond = await keepBonding.unbondedValue(operator)

    return {
      stake: stake.div(tokenDecimalMultiplier),
      bond: bond.div(tokenDecimalMultiplier),
    }
  }
})

describe("FullyBackedSortitionPool", () => {
  const owner = accounts[0]

  const minimumBondableValue = web3.utils.toBN("20").mul(tokenDecimalMultiplier) // 20 ETH

  let keepBonding
  let pool

  let operators

  before(async () => {
    await FullyBackedSortitionPool.detectNetwork()
    await FullyBackedSortitionPool.link("Branch", (await Branch.new()).address)
    await FullyBackedSortitionPool.link(
      "Position",
      (await Position.new()).address,
    )
    await FullyBackedSortitionPool.link(
      "StackLib",
      (await StackLib.new()).address,
    )
    await FullyBackedSortitionPool.link("Leaf", (await Leaf.new()).address)

    keepBonding = await BondingContractStub.new()

    pool = await FullyBackedSortitionPool.new(
      keepBonding.address,
      minimumBondableValue,
      poolWeightDivisor,
      owner,
    )

    operators = []
    for (let i = 0; i < 100; i++) {
      operators.push(web3.eth.accounts.create().address)
    }
  })

  beforeEach(async () => {
    await createSnapshot()
  })

  afterEach(async () => {
    await restoreSnapshot()
  })

  describe("selectSetGroup result distribution", async () => {
    it("is similar between operators with the same unbonded value", async () => {
      await prepareOperator(operators[0], "1000000") // 10k ETH
      await prepareOperator(operators[1], "1000000") // 10k ETH
      await prepareOperator(operators[2], "1000000") // 10k ETH
      await prepareOperator(operators[3], "1000000") // 10k ETH
      await prepareOperator(operators[4], "1000000") // 10k ETH

      const operatorsInPool = operators.slice(0, 5)

      await mineBlocks(11)

      const allSelections = await runSelections(200)
      const stats = reduceResults(operatorsInPool, allSelections)

      // We have 5 operators with the same stake and we are running the
      // selection 200 times. Given that the order does not matter and no
      // repetitions are allowed, each operator should be selected at least
      // 100 times.
      for (const operator of operatorsInPool) {
        if (stats[operator] == 0) {
          assert.fail(`operator ${operator} has never been selected`)
        }
        if (stats[operator] < 100) {
          assert.fail(
            `operator ${operator} should be selected at least 100 times`,
          )
        }
      }
    })

    it("promotes operators with higher unbonded value", async () => {
      for (let i = 0; i < 25; i++) {
        await prepareOperator(operators[i], "1000000") // 1M ETH
      }
      for (let i = 25; i < 50; i++) {
        await prepareOperator(operators[i], "500000") // 500k ETH
      }
      for (let i = 50; i < 75; i++) {
        await prepareOperator(operators[i], "250000") // 250k ETH
      }
      for (let i = 75; i < 100; i++) {
        await prepareOperator(operators[i], "50000") // 50k ETH
      }

      await mineBlocks(11)

      const allSelections = await runSelections(2500)
      const stats = reduceResults(operators, allSelections)

      await assertSelectedMoreOftenThan(
        operators.slice(0, 25),
        operators.slice(25, 50),
        stats,
      )
      await assertSelectedMoreOftenThan(
        operators.slice(25, 50),
        operators.slice(50, 75),
        stats,
      )
      await assertSelectedMoreOftenThan(
        operators.slice(50, 75),
        operators.slice(75, 100),
        stats,
      )
    })
  })

  async function prepareOperator(address, bond) {
    await keepBonding.setBondableValue(
      address,
      web3.utils.toBN(bond).mul(tokenDecimalMultiplier),
    )
    await pool.joinPool(address)
  }

  // Runs the selectSetGroup `times` times and returns concatenated results
  // of all selections.
  async function runSelections(times) {
    let allSelections = []
    let seed = initialSeed

    for (let i = 0; i < times; i++) {
      const group = await pool.selectSetGroup.call(
        groupSize,
        seed,
        minimumBondableValue,
        {from: owner},
      )
      allSelections = allSelections.concat(group)
      seed = web3.utils.soliditySha3(seed)
    }

    return allSelections
  }

  // Asserts whether all operators from `operators` array has been selected more
  // times than all operators from `thanOperators` array. If not, fails the test.
  async function assertSelectedMoreOftenThan(operators, thanOperators, stats) {
    for (operator of operators) {
      for (anotherOperator of thanOperators) {
        if (stats[operator] <= stats[anotherOperator]) {
          assert.fail(
            `operator ${operator} with unbonded value ` +
              `${await operatorUnbondedValue(operator)} ETH ` +
              `was selected ${stats[operator]} times while ` +
              `operator ${anotherOperator} with unbonded value ` +
              `${await operatorUnbondedValue(anotherOperator)} ETH ` +
              `was selected ${stats[anotherOperator]} times`,
          )
        }
      }
    }
  }

  async function operatorUnbondedValue(operator) {
    const bond = await keepBonding.unbondedValue(operator)
    return bond.div(tokenDecimalMultiplier)
  }
})
