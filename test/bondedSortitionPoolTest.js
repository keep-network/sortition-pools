const Sortition = artifacts.require("Sortition")
const Branch = artifacts.require("Branch")
const Position = artifacts.require("Position")
const StackLib = artifacts.require("StackLib")
const Trunk = artifacts.require("Trunk")
const Leaf = artifacts.require("Leaf")
const BondedSortitionPool = artifacts.require('./contracts/BondedSortitionPool.sol')
const BondingContractStub = artifacts.require('BondingContractStub.sol')

contract('BondedSortitionPool', (accounts) => {
    const seed = "0xff39d6cca87853892d2854566e883008bc"
    const bond = 100000000
    let pool

    beforeEach(async () => {
        BondedSortitionPool.link(Branch);
        BondedSortitionPool.link(Position);
        BondedSortitionPool.link(StackLib);
        BondedSortitionPool.link(Trunk);
        BondedSortitionPool.link(Leaf);
        pool = await BondedSortitionPool.new()
        bondingContract = await BondingContractStub.new()
    })

    describe('selectSetGroup', async () => {
        it('returns group of expected size with unique members', async () => {
            await pool.insertOperator(accounts[0], 10)
            await pool.insertOperator(accounts[1], 11)
            await pool.insertOperator(accounts[2], 12)
            await pool.insertOperator(accounts[3], 5)
            await pool.insertOperator(accounts[4], 1)

            let group

            await pool.selectSetGroup(3, seed, bond, bondingContract.address)
            group = await pool.getSetGroup()
            assert.equal(group.length, 3);
            assert.isFalse(hasDuplicates(group))

            await pool.clearSetGroup()

            pool.selectSetGroup(5, seed, bond, bondingContract.address)
            group = await pool.getSetGroup()
            assert.equal(group.length, 5);
            assert.isFalse(hasDuplicates(group))
        })

        function hasDuplicates(array) {
            return (new Set(array)).size !== array.length;
        }

        it('reverts when there are no operators in pool', async () => {
            try {
                await pool.selectSetGroup(3, seed, bond, bondingContract.address)
            } catch (error) {
                assert.include(error.message, "Not enough operators in pool");
                return
            }

            assert.fail('Expected throw not received');
        })

        it('reverts when there are not enough operators in pool', async () => {
            await pool.insertOperator(accounts[0], 10)
            await pool.insertOperator(accounts[1], 11)

            try {
                await pool.selectSetGroup(3, seed, bond, bondingContract.address)
            } catch (error) {
                assert.include(error.message, "Not enough operators in pool");
                return
            }

            assert.fail('Expected throw not received');
        })
    })
})
