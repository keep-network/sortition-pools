const SortitionPool = artifacts.require('./contracts/SortitionPool.sol')

contract('SortitionPool', (accounts) => {
    const seed = "0xff39d6cca87853892d2854566e883008bc"
    let pool
    
    beforeEach(async () => {
        pool = await SortitionPool.new()
    })

    describe('selectGroup', async () => {
        it('returns group of expected size', async() => {
            await pool.insertOperator(accounts[0], 10)
            await pool.insertOperator(accounts[1], 11)
            await pool.insertOperator(accounts[2], 12)

            let group = await pool.selectGroup(3, seed)
            assert.equal(group.length, 3);
        })

        it('reverts when there are no operators in pool', async () => {
            try {
                await pool.selectGroup(3, seed)
            } catch (error) {
                assert.include(error.message, "No operators in pool");
                return
            }

            assert.fail('Expected throw not received');
        })

        it('returns group of expected size if less operators are registered', async() => {
            await pool.insertOperator(accounts[0], 1)
            
            let group = await pool.selectGroup(5, seed)
            assert.equal(group.length, 5);
        })
    })
})