const { time } = require("@openzeppelin/test-helpers")

async function mineBlocks(blocks) {
  for (i = 0; i < blocks; i++) {
    await time.advanceBlock()
  }
}

module.exports = {
  mineBlocks: mineBlocks,
}
