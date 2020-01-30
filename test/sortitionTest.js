const Sortition = artifacts.require('./contracts/Sortition.sol')
const BN = web3.utils.BN
const toHex = web3.utils.numberToHex

contract('Sortition', (accounts) => {
  let sortition
  const alice = accounts[0]
  const bob = accounts[1]
  const carol = accounts[2]
  const david = accounts[3]

  before(async () => {
    sortition = await Sortition.new()
  })

  describe('setLeaf()', async () => {
    it('Sets the leaf correctly', async () => {
      const weight1 = new BN('1234', 16)
      const weight2 = new BN('11', 16)

      const leaf1 = await sortition.toLeaf.call(alice, weight1)
      await sortition.setLeaf(0xecdef, leaf1)
      const res1 = await sortition.getRoot.call()
      assert.equal(toHex(res1), '0x12340000')

      const leaf2 = await sortition.toLeaf.call(bob, weight2)
      await sortition.setLeaf(0xfad00, leaf2)
      const res2 = await sortition.getRoot.call()
      assert.equal(toHex(res2), '0x12340011')
    })
  })

  describe('removeLeaf()', async () => {
    it('uses setLeaf(), which removes a leaf correctly', async () => {
      await sortition.setLeaf(0xecdef, 0)
      await sortition.setLeaf(0xfad00, 0)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0x0')
    })
  })

  describe('insertOperator()', async () => {
    it('Inserts an operator correctly', async () => {
      const weightA = new BN('fff0', 16)
      const weightB = new BN('aaaa', 16)
      const weightC = new BN('f', 16)
      const weightD = new BN('1', 16)

      await sortition.insertOperator(alice, weightA)
      await sortition.insertOperator(bob, weightB)
      await sortition.insertOperator(carol, weightC)
      await sortition.insertOperator(david, weightD)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0xffffaaab00000000000000000000000000000000000000000000000000000000')
    })
  })

  describe('removeOperator()', async () => {
    it('removes an operator correctly', async () => {
      await sortition.removeOperator(david)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0xffffaaaa00000000000000000000000000000000000000000000000000000000')

      const davidLeaf = await sortition.getFlaggedOperatorLeaf.call(david)

      assert.equal(davidLeaf, 0)
    })
  })


  describe('updateLeaf()', async () => {
    it('updates a leaf correctly', async () => {
      await sortition.updateLeaf(0x00000, 0xeee0)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0xeeefaaaa00000000000000000000000000000000000000000000000000000000')
    })
  })

  describe('trunk stacks', async () => {
    it('works as expected', async () => {
      await sortition.removeOperator(alice)

      const deletedLeaf = await sortition.getLeaf.call(0x00000)
      assert.equal(deletedLeaf, 0)

      await sortition.insertOperator(alice, 0xccc0)

      const undeletedLeaf = await sortition.getLeaf.call(0x00000)
      assert.notEqual(undeletedLeaf, 0)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0xcccfaaaa00000000000000000000000000000000000000000000000000000000')
    })
  })

  describe('leaf selection', async () => {
    it('works as expected', async () => {
      const index1 = 0xccd0
      const index2 = 0xccc1

      const position1 = await sortition.pickWeightedLeaf.call(index1)
      assert.equal(position1, 0x10000)

      const leaf1 = await sortition.getLeaf.call(position1)
      const address1 = await sortition.leafAddress.call(leaf1)
      assert.equal(address1, bob)

      const position2 = await sortition.pickWeightedLeaf.call(index2)
      assert.equal(position2, 0x00001)

      const leaf2 = await sortition.getLeaf.call(position2)
      const address2 = await sortition.leafAddress.call(leaf2)
      assert.equal(address2, carol)
      await sortition.pickWeightedLeaf(index2)
    })
  })

  describe('operatorsInPool()', async () => {
    it('works as expected', async () => {
      const nOperators = await sortition.operatorsInPool.call()
      assert.equal(nOperators, 3)
    })
  })
})
