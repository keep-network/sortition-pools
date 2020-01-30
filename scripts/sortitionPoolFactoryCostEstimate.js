const SortitionPoolFactory = artifacts.require('./contracts/SortitionPoolFactory.sol')
const SortitionPool = artifacts.require('./contracts/SortitionPool.sol')

module.exports = async function () {
    let factory

    const seed = "0xff39d6cca87853892d2854566e883008bc"

    const operators = 10

    try {
        // masterContract = await SortitionPool.deployed()
        factory = await SortitionPoolFactory.deployed()

        const poolAddress = await factory.createSortitionPool.call()
        const createPoolTX = await factory.createSortitionPool()

        console.log("createSortitionPool: gas used: ", createPoolTX.receipt.gasUsed)

        const pool = await SortitionPool.at(poolAddress)

        for (i = 0; i < operators; i++) {
            var account = await web3.eth.accounts.create();
            const tx = await pool.insertOperator(account.address, 10)
            console.log(`insertOperator: [${i}]: gas used: ${tx.receipt.gasUsed}`)
        }

        let groupSize = 3
        let selectTX = await pool.selectGroup.estimateGas(groupSize, seed)
        console.log(`selectGroup size: [${groupSize}]: gas used: ${selectTX}`)

        groupSize = 5
        selectTX = await pool.selectGroup.estimateGas(groupSize, seed)
        console.log(`selectGroup size: [${groupSize}]: gas used: ${selectTX}`)

        groupSize = 10
        selectTX = await pool.selectGroup.estimateGas(groupSize, seed)
        console.log(`selectGroup size: [${groupSize}]: gas used: ${selectTX}`)

        groupSize = 30
        selectTX = await pool.selectGroup.estimateGas(groupSize, seed)
        console.log(`selectGroup size: [${groupSize}]: gas used: ${selectTX}`)


        process.exit(0)
    } catch (err) {
        console.error(err)
        process.exit(1)
    }
}
