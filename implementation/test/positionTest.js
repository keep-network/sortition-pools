const Position = artifacts.require('./contracts/Position.sol')
const PositionStub = artifacts.require('PositionStub.sol')
const BN = web3.utils.BN
const utils = require('./utils')

const DEPLOY = [
    { name: 'Position', contract: Position },
    { name: 'PositionStub', contract: PositionStub }]

contract('Position', (accounts) => {
    let positionInstance

    before(async () => {
        deployed = await utils.deploySystem(DEPLOY)
        positionInstance = deployed.PositionStub
    })

    describe('slot()', async () => {
        it('Returns the last bits', async () => {
            const result = await positionInstance.publicSlot.call(0x12345)
            assert.equal(result, 0x5)
        })
    })

    describe('parent()', async () => {
        it('Returns the first bits', async () => {
            const result = await positionInstance.publicParent.call(0x12345)
            assert.equal(result, 0x1234)
        })
    })

    describe('child()', async () => {
        it('Returns the child address', async () => {
            const result = await positionInstance.publicChild.call(0x1234, 0x5)
            assert.equal(result, 0x12345)
        })
    })

    describe('trunk()', async () => {
        it('Returns the trunk number', async () => {
            const result = await positionInstance.publicTrunk.call(0x12345)
            assert.equal(result, 0x1)
        })
    })
})
