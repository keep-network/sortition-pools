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
})