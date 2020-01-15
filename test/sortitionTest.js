const Sortition = artifacts.require('./contracts/Sortition.sol')
const BN = web3.utils.BN
const toHex = web3.utils.numberToHex

contract('Sortition', (accounts) => {
  let sortitionInstance

    let sortition
    let alice = accounts[0]
    let bob = accounts[1]
    let carol = accounts[2]
    let david = accounts[3]

  before(async () => {
      sortitionInstance = await Sortition.new()
      sortition = sortitionInstance


  })

    describe('setLeaf()', async () => {
        it('Sets the leaf correctly', async () => {
            let weight1 = new BN('1234', 16)
            let weight2 = new BN('11', 16)
            let weight3 = new BN('2', 16)
            // let operator2 = accounts[1]

            let leaf1 = await sortition.toLeaf.call(alice, weight1)
            await sortition.setLeaf(0xecdef, leaf1)
            let res1 = await sortition.getRoot.call()
            assert.equal(toHex(res1), '0x12340000')

            let leaf2 = await sortition.toLeaf.call(bob, weight2)
            await sortitionInstance.setLeaf(0xfad00, leaf2)
            let res2 = await sortition.getRoot.call()
            assert.equal(toHex(res2), '0x12340011')
        })
    })

    describe('insert()', async () => {
        it('Inserts an operator correctly', async () => {
            let weightA = new BN('fff0', 16)
            let weightB = new BN('aaaa', 16)
            let weightC = new BN('f', 16)
            let weightD = new BN('1', 16)

            await sortition.insert(alice, weightA)
            await sortition.insert(bob, weightB)
            await sortition.insert(carol, weightC)
            await sortition.insert(david, weightD)

            let root = await sortition.getRoot.call()

            assert.equal(toHex(root), '0xffffaaab00000000000000000000000000000000000000000000000012340011')
        })
    })

    describe('removeLeaf()', async () => {
        it('removes a leaf correctly', async () => {
            await sortition.removeLeaf(0xecdef)
            await sortition.removeLeaf(0xfad00)

            let root = await sortition.getRoot.call()

            assert.equal(toHex(root), '0xffffaaab00000000000000000000000000000000000000000000000000000000')
        })
    })

    describe('removeOperator()', async () => {
        it('removes an operator correctly', async () => {
            await sortition.removeOperator(david)

            let root = await sortition.getRoot.call()

            assert.equal(toHex(root), '0xffffaaaa00000000000000000000000000000000000000000000000000000000')

            let davidLeaf = await sortition.getFlaggedOperatorLeaf.call(david)

            assert.equal(davidLeaf, 0)
        })
    })


    describe('updateLeaf()', async () => {
        it('updates a leaf correctly', async () => {
            await sortition.updateLeaf(0x00000, 0xeee0)

            let root = await sortition.getRoot.call()

            assert.equal(toHex(root), '0xeeefaaaa00000000000000000000000000000000000000000000000000000000')
        })
    })

    describe('trunk stacks', async () => {
        it('works as expected', async () => {
            await sortition.removeLeaf(0x00000)

            let deletedLeaf = await sortition.getLeaf.call(0x00000)
            assert.equal(deletedLeaf, 0)

            await sortition.insert(alice, 0xccc0)

            let undeletedLeaf = await sortition.getLeaf.call(0x00000)
            assert.notEqual(undeletedLeaf, 0)

            let root = await sortition.getRoot.call()

            assert.equal(toHex(root), '0xcccfaaaa00000000000000000000000000000000000000000000000000000000')
        })
    })

    describe('leaf selection', async () => {
        it('works as expected', async () => {
            let index1 = 0xccd0
            let index2 = 0xccc1

            let position1 = await sortition.pickWeightedLeaf.call(index1)
            assert.equal(position1, 0x10000)

            let leaf1 = await sortition.getLeaf.call(position1)
            let address1 = await sortition.leafAddress.call(leaf1)
            assert.equal(address1, bob)

            let position2 = await sortition.pickWeightedLeaf.call(index2)
            assert.equal(position2, 0x00001)

            let leaf2 = await sortition.getLeaf.call(position2)
            let address2 = await sortition.leafAddress.call(leaf2)
            assert.equal(address2, carol)
            await sortition.pickWeightedLeaf(index2)
        })
    })

    describe('multi-leaf selection', async () => {
        it('works as expected', async () => {
            let index1 = 0x1234
            let index2 = 0xccc1
            let index3 = 0xf000

            let ps = await sortition.pickThreeLeaves.call(index1, index2, index3)
            assert.equal(ps, 0x10001)

            await sortition.pickThreeLeaves(index1, index2, index3)
        })
    })
})