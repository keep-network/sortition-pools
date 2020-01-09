const Position = artifacts.require('./contracts/Position.sol')

const BN = web3.utils.BN

contract('Position', (accounts) => {
    let positionInstance

    before(async () => {
        positionInstance = await Position.new()
    })

    describe('slot()', async () => {
        it('Returns the last bits', async () => {
            const result = await positionInstance.slot.call(0x12345)
            assert.equal(result, 0x5)
        })
    })

    describe('parent()', async () => {
        it('Returns the first bits', async () => {
            const result = await positionInstance.parent.call(0x12345)
            assert.equal(result, 0x1234)
        })
    })

    describe('child()', async () => {
        it('Returns the child address', async () => {
            const result = await positionInstance.child.call(0x1234, 0x5)
            assert.equal(result, 0x12345)
        })
    })
})
