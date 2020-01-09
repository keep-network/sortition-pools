const Sortition = artifacts.require('./contracts/Sortition.sol')
const BN = web3.utils.BN
const toHex = web3.utils.numberToHex

contract('Sortition', (accounts) => {
  let sortitionInstance

  before(async () => {
    sortitionInstance = await Sortition.new()
  })

  describe('init()', async () => {
    it('Returns correct contract owner', async () => {
        const owner = await sortitionInstance.getOwner.call()
        assert.equal(owner, accounts[0])
    })
  })

    describe('setLeaf()', async () => {
        it('Sets the leaf correctly', async () => {
            let operator1 = accounts[0]
            let operator2 = accounts[1]
            let operator3 = accounts[2]
            let weight1 = new BN('1234', 16)
            let weight2 = new BN('11', 16)
            let weight3 = new BN('2', 16)
            // let operator2 = accounts[1]
            res1 = await sortitionInstance.setLeaf.call(0xbcdef, operator1, weight1)
            assert.equal(toHex(res1), '0x12340000000000000000')

            // root = await sortitionInstance.root.call()
            // assert.equal(toHex(root), '0x12340000000000000000')

            res2 = await sortitionInstance.setLeaf.call(0xfad00, operator2, weight2)
            assert.equal(toHex(res2), '0x12340000000000000011')
        })
    })
})
