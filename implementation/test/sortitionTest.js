const Sortition = artifacts.require('./contracts/Sortition.sol')

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
})