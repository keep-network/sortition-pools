const SortitionStub = artifacts.require('SortitionStub.sol')
const StackLib = artifacts.require('StackLib.sol')
const Branch = artifacts.require('Branch.sol')
const Position = artifacts.require('Position.sol')
const BN = web3.utils.BN
const utils = require('./utils')

const DEPLOY = [
    { name: 'StackLib', contract: StackLib },
    { name: 'Branch', contract: Branch },
    { name: 'Position', contract: Position },
    { name: 'SortitionStub', contract: SortitionStub }]


contract('Stack', (accounts) => {
  let deployed

  before(async () => {
    deployed = await utils.deploySystem(DEPLOY)
  })

  describe('Stack', async () => {
    it('correctly pushes and peeks values', async () => {
        await deployed.SortitionStub.stackPush(new BN(5))
        await deployed.SortitionStub.stackPush(new BN(4))
        await deployed.SortitionStub.stackPush(new BN(3))
        const size = await deployed.SortitionStub.getSize.call()

        const value = await deployed.SortitionStub.stackPeek.call()
        assert.equal(value, 3)
        assert.equal(size, 3)

    })

    it('correctly pops from stack', async () => {
        await deployed.SortitionStub.stackPush(new BN(2))
        await deployed.SortitionStub.stackPush(new BN(1))
        await deployed.SortitionStub.stackPop()
        const value = await deployed.SortitionStub.stackPeek.call()
        assert.equal(value, 2)

    })
  })
})
