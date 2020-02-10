const StackLib = artifacts.require('StackLib')
const Branch = artifacts.require('Branch')
const Position = artifacts.require('Position')
const Trunk = artifacts.require('Trunk')
const Leaf = artifacts.require('Leaf')
const SortitionTreeStub = artifacts.require('SortitionTreeStub.sol')

const BN = web3.utils.BN
const toHex = web3.utils.numberToHex

contract('SortitionTree', (accounts) => {
  let sortition
  const alice = accounts[0]
  const bob = accounts[1]
  const carol = accounts[2]
  const david = accounts[3]

  before(async () => {
    SortitionTreeStub.link(StackLib)
    SortitionTreeStub.link(Branch)
    SortitionTreeStub.link(Position)
    SortitionTreeStub.link(Trunk)
    SortitionTreeStub.link(Leaf)
    sortition = await SortitionTreeStub.new()
  })

  describe('setLeaf()', async () => {
    it('Sets the leaf correctly', async () => {
      const weight1 = new BN('1234', 16)
      const weight2 = new BN('11', 16)

      const leaf1 = await sortition.toLeaf.call(alice, weight1)
      await sortition.publicSetLeaf(0xecdef, leaf1)
      const res1 = await sortition.getRoot.call()
      assert.equal(toHex(res1), '0x12340000')

      const leaf2 = await sortition.toLeaf.call(bob, weight2)
      await sortition.publicSetLeaf(0xfad00, leaf2)
      const res2 = await sortition.getRoot.call()
      assert.equal(toHex(res2), '0x12340011')
    })
  })

  describe('removeLeaf()', async () => {
    it('uses setLeaf(), which removes a leaf correctly', async () => {
      await sortition.publicSetLeaf(0xecdef, 0)
      await sortition.publicSetLeaf(0xfad00, 0)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0x0')
    })
  })

  describe('insertOperator()', async () => {
    const weightA = new BN('fff0', 16)
    const weightB = new BN('aaaa', 16)
    const weightC = new BN('f', 16)
    const weightD = new BN('1', 16)

    it('Inserts an operator correctly', async () => {
      await sortition.publicInsertOperator(alice, weightA)
      await sortition.publicInsertOperator(bob, weightB)
      await sortition.publicInsertOperator(carol, weightC)
      await sortition.publicInsertOperator(david, weightD)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0xffffaaab00000000000000000000000000000000000000000000000000000000')
    })

    it('reverts if operator is already registered', async () => {
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
      await sortition.publicRemoveOperator(david)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0xffffaaaa00000000000000000000000000000000000000000000000000000000')

      const davidLeaf = await sortition.publicGetFlaggedOperatorLeaf.call(david)

      assert.equal(davidLeaf, 0)
    })

    it('reverts if operator is not registered', async () => {
      try {
        await sortition.publicRemoveOperator('0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
      } catch (error) {
        assert.include(error.message, 'Operator is not registered in the pool')
        return
      }

      assert.fail('Expected throw not received')
    })
  })

  describe('isOperatorRegistered()', async () => {
    it('returns true if operator is registered', async () => {
      const result = await sortition.publicIsOperatorRegistered(alice)

      assert.isTrue(result)
    })

    it('returns false if operator is not registered', async () => {
      const result = await sortition.publicIsOperatorRegistered('0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')

      assert.isFalse(result)
    })
  })

  describe('updateLeaf()', async () => {
    it('updates a leaf correctly', async () => {
      await sortition.publicUpdateLeaf(0x00000, 0xeee0)

      const root = await sortition.getRoot.call()

      assert.equal(toHex(root), '0xeeefaaaa00000000000000000000000000000000000000000000000000000000')
    })
  })

  describe('trunk stacks', async () => {
    it('works as expected', async () => {
      await sortition.publicRemoveOperator(alice)

      const deletedLeaf = await sortition.getLeaf.call(0x00000)
      assert.equal(deletedLeaf, 0)

      await sortition.publicInsertOperator(alice, 0xccc0)

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

      const position1 = await sortition.publicPickWeightedLeaf.call(index1)
      assert.equal(position1, 0x10000)

      const leaf1 = await sortition.getLeaf.call(position1)
      const address1 = await sortition.leafAddress.call(leaf1)
      assert.equal(address1, bob)

      const position2 = await sortition.publicPickWeightedLeaf.call(index2)
      assert.equal(position2, 0x00001)

      const leaf2 = await sortition.getLeaf.call(position2)
      const address2 = await sortition.leafAddress.call(leaf2)
      assert.equal(address2, carol)
    })
  })

  describe('operatorsInPool()', async () => {
    it('works as expected', async () => {
      const nOperators = await sortition.operatorsInPool.call()
      assert.equal(nOperators, 3)
    })
  })
})