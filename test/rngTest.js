const RNG = artifacts.require('./contracts/RNG.sol')
const RNGStub = artifacts.require('RNGStub.sol')

const toHex = web3.utils.numberToHex
const toNum = web3.utils.hexToNumber
const utils = require('./utils')

const DEPLOY = [
  { name: 'RNG', contract: RNG },
  { name: 'RNGStub', contract: RNGStub }]

contract('RNG', (accounts) => {
  let rngInstance

  before(async () => {
    deployed = await utils.deploySystem(DEPLOY)
    rngInstance = deployed.RNGStub

    indices = [451, 2945, 3017, 3120]
    weights = [1997, 72, 35, 1984]
    weightSum = 4088
  })

  describe('bitsRequired()', async () => {
    it('Returns the number of bits required', async () => {
      a = 2 ** 19 - 1
      b = 2 ** 16
      c = 2 ** 10 + 1
      d = 2

      ba = await rngInstance.bitsRequired.call(a)
      bb = await rngInstance.bitsRequired.call(b)
      bc = await rngInstance.bitsRequired.call(c)
      bd = await rngInstance.bitsRequired.call(d)

      assert.equal(ba, 19)
      assert.equal(bb, 16)
      assert.equal(bc, 11)
      assert.equal(bd, 1)
    })
  })

  describe('truncate()', async () => {
    it('Truncates a number to the correct number of bits', async () => {
      a = 0xffffffff

      b = await rngInstance.truncate.call(1, a)
      c = await rngInstance.truncate.call(2, a)
      d = await rngInstance.truncate.call(16, a)
      e = await rngInstance.truncate.call(31, a)
      f = await rngInstance.truncate.call(32, a)
      g = await rngInstance.truncate.call(64, a)

      assert.equal(b, 0x1)
      assert.equal(c, 0x3)
      assert.equal(d, 0xffff)
      assert.equal(e, 0x7fffffff)
      assert.equal(f, a)
      assert.equal(g, a)
    })
  })

  describe('getIndex()', async () => {
    it('Returns an index smaller than the range', async () => {
      r = 0x12345
      s = 0x0deadbeef

      i = await rngInstance.getIndex.call(r, s)

      assert.isBelow(toNum(toHex(i)), r)
    })
  })

  describe('getManyIndices()', async () => {
    it('Has reasonable gas costs (less than 600 per call)', async () => {
      r = 0x12345

      times = 1000

      tx = await rngInstance.getManyIndices(r, times)

      gasCost = (tx.receipt.gasUsed - 21000) / times

      assert.isBelow(gasCost, 600)
    })
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

  describe('uniquifyIndex()', async () => {
    // previously selected: bob, billybob, sandy, mark
    // indices = [451, 2945, 3017, 3120]
    // weights = [1997, 72, 35, 1984]
    // weightSum = 4088

    it('returns the truncated index unchanged when applicable', async () => {
      // alice's last index
      t = 450
      i = await rngInstance.uniquifyIndex.call(t, indices, weights)

      assert.equal(i, t)
    }),

    it('maps the truncated index to a free index', async () => {
      // first index after alice -> phyllis' first index
      t = 451
      i = await rngInstance.uniquifyIndex.call(t, indices, weights)

      assert.equal(i, 2448)
    })

    it('skips as many previous leaves as is required', async () => {
      // this should return rocky's first index
      t = 948
      i = await rngInstance.uniquifyIndex.call(t, indices, weights)

      assert.equal(i, 3052)
    })

    it('skips all previous leaves if required', async () => {
      // this should return william's first index
      t = 1016
      i = await rngInstance.uniquifyIndex.call(t, indices, weights)

      assert.equal(i, 5104)
    })
  })
})
