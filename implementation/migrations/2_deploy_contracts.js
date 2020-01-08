const Sortition = artifacts.require("Sortition");

module.exports = function(deployer) {
  deployer.deploy(Sortition);
};
