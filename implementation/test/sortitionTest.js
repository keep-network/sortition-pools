const Sortition = artifacts.require('./contracts/Sortition.sol')
const BN = web3.utils.BN
const toHex = web3.utils.numberToHex

contract('Sortition', (accounts) => {
  let sortitionInstance

    let sortition
    let alice = accounts[0]
    let bob = accounts[1]
    let carol = accounts[2]
  before(async () => {
      sortitionInstance = await Sortition.new()
      sortition = sortitionInstance


  })

  describe('init()', async () => {
    it('Returns correct contract owner', async () => {
        const owner = await sortitionInstance.getOwner.call()
        assert.equal(owner, accounts[0])
    })
  })

    describe('setLeaf()', async () => {
        it('Sets the leaf correctly', async () => {
            let weight1 = new BN('1234', 16)
            let weight2 = new BN('11', 16)
            let weight3 = new BN('2', 16)
            // let operator2 = accounts[1]
            await sortition.setLeaf(0xecdef, alice, weight1)
            let res1 = await sortition.getRoot.call()
            assert.equal(toHex(res1), '0x12340000')

            await sortitionInstance.setLeaf(0xfad00, bob, weight2)
            let res2 = await sortition.getRoot.call()
            assert.equal(toHex(res2), '0x12340011')
        })
    })

    describe('insert()', async () => {
        it('Inserts an operator correctly', async () => {
            let weightA = new BN('f000', 16)
            let weightB = new BN('aaaa', 16)
            let weightC = new BN('11', 16)

            await sortition.insert(alice, weightA)
            await sortition.insert(bob, weightB)
            await sortition.insert(carol, weightC)

            let root = await sortition.getRoot.call()

            assert.equal(toHex(root), '0xf011aaaa00000000000000000000000000000000000000000000000012340011')
        })
    })
})
