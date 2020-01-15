const RNG = artifacts.require('./contracts/RNG.sol')
const RNGStub = artifacts.require('RNGStub.sol')

const BN = web3.utils.BN
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
    })

    describe('bitsRequired()', async () => {
        it('Returns the number of bits required', async () => {
            a = 2**19 - 1
            b = 2**16
            c = 2**10 + 1
            d = 2
            e = 2**19

            ba = await rngInstance.bitsRequired.call(a)
            bb = await rngInstance.bitsRequired.call(b)
            bc = await rngInstance.bitsRequired.call(c)
            bd = await rngInstance.bitsRequired.call(d)

            assert.equal(ba, 19)
            assert.equal(bb, 16)
            assert.equal(bc, 11)
            assert.equal(bd, 1)

            await rngInstance.bitsRequired(e)
        })
    })

    describe('truncate()', async () => {
        it('Truncates a number to the correct number of bits', async () => {
            a = 0xffffffff

            b = await rngInstance.truncate.call(1, a)
            c = await rngInstance.truncate.call(2, a)
            d = await rngInstance.truncate.call(16, a)
            e = await rngInstance.truncate.call(31, a)
            f = await rngInstance.truncate.call(64, a)

            assert.equal(b, 0x1)
            assert.equal(c, 0x3)
            assert.equal(d, 0xffff)
            assert.equal(e, 0x7fffffff)
            assert.equal(f, a)
        })
    })

    describe('getIndex()', async () => {
        it('Returns an index smaller than the range', async () => {
            r = 0x12345
            s = 0x0deadbeef

            i = await rngInstance.getIndex.call(r, s)

            assert.isBelow(toNum(toHex(i)), r)

            await rngInstance.getIndex(r, i)
        })
    })

    describe('getManyIndices()', async () => {
        it('Has reasonable gas costs (1000 calls)', async () => {
            r = 0x12345
            s = 0x0bad1dea

            i = await rngInstance.getIndex.call(r, s)

            assert.isBelow(toNum(toHex(i)), r)

            await rngInstance.getManyIndices(r, 1000)
        })
    })
})
