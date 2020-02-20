const StackLib = artifacts.require('StackLib')
const Branch = artifacts.require('Branch')
const Position = artifacts.require('Position')
const Leaf = artifacts.require('Leaf')
const SortitionTreeStub = artifacts.require('SortitionTreeStub.sol')

const toHex = web3.utils.numberToHex

contract('SortitionTree', (accounts) => {
  let sortition
  const alice = accounts[0]
  const bob = accounts[1]

  before(async () => {
    SortitionTreeStub.link(StackLib)
    SortitionTreeStub.link(Branch)
    SortitionTreeStub.link(Position)
    SortitionTreeStub.link(Leaf)
  })

  beforeEach(async () => {
    sortition = await SortitionTreeStub.new()
  })

  describe('setLeaf()', async () => {
    it('Sets the leaf correctly', async () => {
      const weight1 = 0x1234
      const position1 = parseInt('00123456', 8)
      const weight2 = 0x11
      const position2 = parseInt('01234567', 8)

      const leaf1 = await sortition.toLeaf.call(alice, weight1)
      await sortition.publicSetLeaf(position1, leaf1)
      const res1 = await sortition.getRoot.call()
      assert.equal(toHex(res1), '0x1234')

      const leaf2 = await sortition.toLeaf.call(bob, weight2)
      await sortition.publicSetLeaf(position2, leaf2)
      const res2 = await sortition.getRoot.call()
      assert.equal(toHex(res2), '0x1100001234')
    })
  })

  describe('removeLeaf()', async () => {
    it('removes a leaf correctly', async () => {
      const weight1 = 0x1234
      const position1 = parseInt('00123456', 8)
      const weight2 = 0x11
      const position2 = parseInt('01234567', 8)

      const leaf1 = await sortition.toLeaf.call(alice, weight1)
      await sortition.publicSetLeaf(position1, leaf1)

      const leaf2 = await sortition.toLeaf.call(bob, weight2)
      await sortition.publicSetLeaf(position2, leaf2)
      await sortition.publicRemoveLeaf(position1)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0x1100000000')
    })
  })

  describe('insertOperator()', async () => {
    const weightA = 0xfff0
    const weightB = 0x10000001

    it('Inserts an operator correctly', async () => {
      await sortition.publicInsertOperator(alice, weightA)
      await sortition.publicInsertOperator(bob, weightB)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0x1000fff1')
    })

    it('reverts if operator is already registered', async () => {
      await sortition.publicInsertOperator(alice, weightA)
      try {
        await sortition.publicInsertOperator(alice, weightB)
      } catch (error) {
        assert.include(error.message, 'Operator is already registered in the pool')
        return
      }

      assert.fail('Expected throw not received')
    })
  })

  describe('removeOperator()', async () => {
    it('removes an operator correctly', async () => {
      await sortition.publicInsertOperator(alice, 0x1234)
      await sortition.publicRemoveOperator(alice)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0x0')

      const aliceLeaf = await sortition.publicGetFlaggedLeafPosition.call(alice)

      assert.equal(aliceLeaf, 0)
    })

    it('reverts if operator is not registered', async () => {
      await sortition.publicInsertOperator(alice, 0x1234)
      try {
        await sortition.publicRemoveOperator(bob)
      } catch (error) {
        assert.include(error.message, 'Operator is not registered in the pool')
        return
      }

      assert.fail('Expected throw not received')
    })
  })

  describe('isOperatorRegistered()', async () => {
    it('returns true if operator is registered', async () => {
      await sortition.publicInsertOperator(alice, 0x1234)
      const result = await sortition.publicIsOperatorRegistered(alice)

      assert.isTrue(result)
    })

    it('returns false if operator is not registered', async () => {
      await sortition.publicInsertOperator(alice, 0x1234)
      const result = await sortition.publicIsOperatorRegistered(bob)

      assert.isFalse(result)
    })
  })

  describe('updateLeaf()', async () => {
    it('updates a leaf correctly', async () => {
      await sortition.publicInsertOperator(alice, 0x1234)
      await sortition.publicUpdateLeaf(0x00000, 0x9876)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0x9876')
    })
  })

  describe('trunk stacks', async () => {
    it('works as expected', async () => {
      await sortition.publicInsertOperator(alice, 0x1234)
      await sortition.publicInsertOperator(bob, 0x9876)

      await sortition.publicRemoveOperator(alice)
      const deletedLeaf = await sortition.getLeaf.call(0x00000)
      assert.equal(deletedLeaf, 0)

      await sortition.publicInsertOperator(alice, 0xdead)

      const stillDeletedLeaf = await sortition.getLeaf.call(0x00000)
      assert.equal(stillDeletedLeaf, 0)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0x17723')
    })
  })

  describe('leaf selection', async () => {
    it('works as expected', async () => {
      await sortition.publicInsertOperator(alice, 451)
      await sortition.publicInsertOperator(bob, 1984)
      const index1 = 450
      const index2 = 451

      const position1 = await sortition.publicPickWeightedLeaf.call(index1)
      assert.equal(position1, 0)

      const leaf1 = await sortition.getLeaf.call(position1)
      const address1 = await sortition.leafAddress.call(leaf1)
      assert.equal(address1, alice)

      const position2 = await sortition.publicPickWeightedLeaf.call(index2)
      assert.equal(position2, 1)

      const leaf2 = await sortition.getLeaf.call(position2)
      const address2 = await sortition.leafAddress.call(leaf2)
      assert.equal(address2, bob)
    })
  })

  describe('operatorsInPool()', async () => {
    it('works as expected', async () => {
      await sortition.publicInsertOperator(alice, 1)
      const nOperators = await sortition.operatorsInPool.call()
      assert.equal(nOperators, 1)
    })
  })
})
