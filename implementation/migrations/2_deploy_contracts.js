const Sortition = artifacts.require("Sortition");
const Branch = artifacts.require("Branch");

module.exports = function(deployer) {
  deployer.deploy(Sortition);
  deployer.deploy(Branch);
};
