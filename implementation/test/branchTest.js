const Branch = artifacts.require('./contracts/Branch.sol')

const BN = web3.utils.BN
const toHex = web3.utils.numberToHex

contract('Branch', (accounts) => {
    let branchInstance

    before(async () => {
        branchInstance = await Branch.new()
    })

    describe('getSlot()', async () => {
        it('Returns the uint16 in the correct position', async () => {
            node = new BN('0x0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff', 16)

            const result = await branchInstance.getSlot.call(node, 3)
            assert.equal(result, 0x3333)
        })
    })

    describe('setSlot()', async () => {
        it('Changes the correct slot', async () => {

            node = new BN('0x0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff', 16)
            newNode = '0x111122221234444455556666777788889999aaaabbbbccccddddeeeeffff'
            w = new BN('0x1234', 16)

            const modified = await branchInstance.setSlot.call(node, 3, w)
            newSlot = await branchInstance.getSlot.call(modified, 3)
            assert.equal(toHex(modified), newNode)
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
