const deployContracts = require("./scripts/deployContracts")

module.exports = async function (deployer) {
  await deployContracts(artifacts, deployer)
};
