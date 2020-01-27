const Branch = artifacts.require('./contracts/Branch.sol')
const BranchStub = artifacts.require('BranchStub.sol')

const BN = web3.utils.BN
const toHex = web3.utils.numberToHex
const utils = require('./utils')

const DEPLOY = [
    { name: 'Branch', contract: Branch },
    { name: 'BranchStub', contract: BranchStub }]

contract('Branch', (accounts) => {
    let branchInstance

    before(async () => {
        deployed = await utils.deploySystem(DEPLOY)
        branchInstance = deployed.BranchStub
    })

    describe('getSlot()', async () => {
        it('Returns the uint16 in the correct position', async () => {
            node = new BN('0x0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff', 16)

            const result = await branchInstance.getSlot.call(node, 3)
            assert.equal(result, 0x3333)
        })
    })

    describe('clearSlot()', async () => {
        it('Clears the correct slot', async () => {
            node = new BN('0x0000111122220000444455556666777788889999aaaabbbbccccddddeeeeffff', 16)
            newNode = '0x111122220000444455556666777788889999aaaabbbbccccddddeeeeffff'

            const result = await branchInstance.clearSlot.call(node, 3)
            assert.equal(toHex(result), newNode)
        })
    })

    describe('setSlot()', async () => {
        it('Changes the correct slot', async () => {

            node = new BN('0x0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff', 16)
            newNode = '0x111122221234444455556666777788889999aaaabbbbccccddddeeeeffff'
            w = 0x1234

            const modified = await branchInstance.setSlot.call(node, 3, w)
            newSlot = await branchInstance.getSlot.call(modified, 3)
            assert.equal(toHex(modified), newNode)
        }),

        it('Ruins your damn day if `weight` overflows', async () => {
            node = 0x12340000
            w = 0x11234

            const modified = await branchInstance.setSlot.call(node, 15, w)
            screwedUpSlot = await branchInstance.getSlot.call(modified, 14)
            assert.equal(screwedUpSlot, 0x1235)
        })
    })

    describe('sumWeight()', async () => {
        it('Returns the correct weight', async () => {

            node = new BN('0x0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff', 16)
            const weight = await branchInstance.sumWeight.call(node)
            expected = 0xffff * 8
            assert.equal(weight, expected)
        })
    })
})
