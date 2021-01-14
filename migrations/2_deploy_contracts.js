const SortitionPoolsDeployer = require("./scripts/deployContracts")

module.exports = async function (deployer) {
  const sortitionPoolsDeployer = new SortitionPoolsDeployer(deployer, artifacts)

  await sortitionPoolsDeployer.deploySortitionPoolFactory()
  await sortitionPoolsDeployer.deployBondedSortitionPoolFactory()
  await sortitionPoolsDeployer.deployFullyBackedSortitionPoolFactory()
}
