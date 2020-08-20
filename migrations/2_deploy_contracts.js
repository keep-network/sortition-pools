const {
  deploySortitionPoolFactory,
  deployBondedSortitionPoolFactory,
  deployFullyBackedSortitionPoolFactory,
} = require("./scripts/deployContracts")

module.exports = async function (deployer) {
  await deploySortitionPoolFactory(artifacts, deployer)
  await deployBondedSortitionPoolFactory(artifacts, deployer)
  await deployFullyBackedSortitionPoolFactory(artifacts, deployer)
}
