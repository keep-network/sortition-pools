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
            d = 2**19

            ba = await rngInstance.bitsRequired.call(a)
            bb = await rngInstance.bitsRequired.call(b)
            bc = await rngInstance.bitsRequired.call(c)

            assert.equal(ba, 19)
            assert.equal(bb, 16)
            assert.equal(bc, 11)

            await rngInstance.bitsRequired(d)
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
        it('Has reasonable gas costs', async () => {
            r = 0x12345
            s = 0x0bad1dea

            i = await rngInstance.getIndex.call(r, s)

            assert.isBelow(toNum(toHex(i)), r)

            await rngInstance.getManyIndices(r, 100)
        })
    })
})
