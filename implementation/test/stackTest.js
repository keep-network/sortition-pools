const SortitionStub = artifacts.require('SortitionStub.sol')
const StackLib = artifacts.require('StackLib.sol')
const BN = web3.utils.BN
const utils = require('./utils')

const DEPLOY = [
    { name: 'StackLib', contract: StackLib },
    { name: 'SortitionStub', contract: SortitionStub }]


contract('Sortition', (accounts) => {
  let deployed

  before(async () => {
    deployed = await utils.deploySystem(DEPLOY)
  })

  describe('Stack', async () => {
    it('correctly pushes and peeks values', async () => {
        await deployed.SortitionStub.stackPush(new BN(5))
        await deployed.SortitionStub.stackPush(new BN(4))
        await deployed.SortitionStub.stackPush(new BN(3))
        const value = await deployed.SortitionStub.getSize.call()
        console.log(value)
        assert.equal(value, 3)
    })
  })
})