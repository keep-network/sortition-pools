const Operator = artifacts.require('./contracts/Operator.sol')
const OperatorStub = artifacts.require('OperatorStub.sol')

// const toHex = web3.utils.numberToHex
// const toNum = web3.utils.hexToNumber
const utils = require('./utils')

const DEPLOY = [
  { name: 'Operator', contract: Operator },
  { name: 'OperatorStub', contract: OperatorStub }]

contract('Operator', (accounts) => {
  let operator

  before(async () => {
    deployed = await utils.deploySystem(DEPLOY)
    operator = deployed.OperatorStub

    indices = [451, 2945, 3017, 3120]
    weights = [1997, 72, 35, 1984]
    weightSum = 4088
  })

  // alice 451
  // bob 1997
  // phyllis 497
  // billybob 72
  // sandy 35
  // rocky 68
  // mark 1984
  // william 9000

  // alice 0
  // bob 451
  // phyllis 2448
  // billybob 2945
  // sandy 3017
  // rocky 3052
  // mark 3120
  // william 5104
  // total 14104

  describe('skip()', async () => {
    // previously selected: bob, billybob, sandy, mark
    // indices = [451, 2945, 3017, 3120]
    // weights = [1997, 72, 35, 1984]
    // weightSum = 4088

    it('returns the truncated index unchanged when applicable', async () => {
      // alice's last index
      t = 450
      i = await operator.skip(t, indices, weights)

      assert.equal(i, t)
    }),

    it('maps the truncated index to a free index', async () => {
      // first index after alice -> phyllis' first index
      t = 451
      i = await operator.skip(t, indices, weights)

      assert.equal(i, 2448)
    })

    it('skips as many previous leaves as is required', async () => {
      // this should return rocky's first index
      t = 948
      i = await operator.skip(t, indices, weights)

      assert.equal(i, 3052)
    })

    it('skips all previous leaves if required', async () => {
      // this should return william's first index
      t = 1016
      i = await operator.skip(t, indices, weights)

      assert.equal(i, 5104)
    })
  })
})
