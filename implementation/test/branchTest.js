const Branch = artifacts.require('./contracts/Branch.sol')

const BN = web3.utils.BN

contract('Branch', (accounts) => {
    let branchInstance

    before(async () => {
        branchInstance = await Branch.new()
    })

    describe('getSlot()', async () => {
        it('Returns the uint16 in the correct position', async () => {

            node = new BN('0x0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff', 16)

            const r = await branchInstance.toBytes.call(node)
            console.log(r)

            const result = await branchInstance.getSlot.call(node, 3)
            console.log(result.toString())
            assert.equal(result, 0x3333)
        })
    })

    describe('setSlot()', async () => {
        it('Changes the correct slot', async () => {

            node = new BN('0x0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff', 16)
            w = new BN('0x1234', 16)

            const modified = await branchInstance.setSlot.call(node, 3, w)
            newSlot = await branchInstance.getSlot.call(modified, 3)
            assert.equal(newSlot, 0x1234)
        })
    })

    describe('sumWeight()', async () => {
        it('Changes the correct slot', async () => {

            node = new BN('0x0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff', 16)
            const weight = await branchInstance.sumWeight.call(node)
            expected = 0xffff * 8
            assert.equal(weight, expected)
        })
    })
})
