const Branch = artifacts.require("Branch")
const Position = artifacts.require("Position")
const StackLib = artifacts.require("StackLib")
const Trunk = artifacts.require("Trunk")
const Leaf = artifacts.require("Leaf")
const SortitionPool = artifacts.require("SortitionPool")

module.exports = async function () {
    const seed = "0xff39d6cca87853892d2854566e883008bc"

    const operators = 64

    try {
        await SortitionPool.link(Branch);
        await SortitionPool.link(Position);
        await SortitionPool.link(StackLib);
        await SortitionPool.link(Trunk);
        await SortitionPool.link(Leaf);

        const pool = await SortitionPool.new()

        const receipt = await web3.eth.getTransactionReceipt(pool.transactionHash)

        console.log("SortitionPool.new: gas used: ", web3.utils.toBN(receipt.gasUsed).toNumber())
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
