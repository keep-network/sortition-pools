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

            const result = await branchInstance.getSlot.call(node, 3)
            assert.equal(result, 0x3333)
        })
    })
})