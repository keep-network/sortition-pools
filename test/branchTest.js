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
      node = new BN('0x0000000011111111222222223333333344444444555555556666666677777777', 16)

      const result = await branchInstance.getSlot.call(node, 3)
      assert.equal(result, 0x33333333)
    })
  })

  describe('clearSlot()', async () => {
    it('Clears the correct slot', async () => {
      node = new BN('0x0000000011111111222222223333333344444444555555556666666677777777', 16)
      newNode ='0x11111111222222220000000044444444555555556666666677777777'

      const result = await branchInstance.clearSlot.call(node, 3)
      assert.equal(toHex(result), newNode)
    })
  })

  describe('setSlot()', async () => {
    it('Changes the correct slot', async () => {
      node = new BN('0x0000000011111111222222223333333344444444555555556666666677777777', 16)
      newNode ='0x11111111222222221234567844444444555555556666666677777777'
      w = 0x12345678

      const modified = await branchInstance.setSlot.call(node, 3, w)
      newSlot = await branchInstance.getSlot.call(modified, 3)
      assert.equal(toHex(modified), newNode)
    })
  })

  describe('sumWeight()', async () => {
    it('Returns the correct weight', async () => {
      node = new BN('0x0000000011111111222222223333333344444444555555556666666677777777', 16)
      const weight = await branchInstance.sumWeight.call(node)
      expected = 0x77777777 * 4
      assert.equal(weight, expected)
    })
  })
})
