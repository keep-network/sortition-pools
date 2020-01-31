const {
  deploySortitionPoolFactory,
  deployBondedSortitionPoolFactory
} = require("./scripts/deployContracts")

module.exports = async function (deployer) {
  await deploySortitionPoolFactory(artifacts, deployer)
  await deployBondedSortitionPoolFactory(artifacts, deployer)
};
