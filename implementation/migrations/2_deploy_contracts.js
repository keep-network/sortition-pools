const Sortition = artifacts.require("Sortition");
const Branch = artifacts.require("Branch");
const StackLib = artifacts.require("StackLib");


module.exports = function(deployer) {
  deployer.deploy(Sortition);
  deployer.deploy(Branch);
  deployer.link(Sortition, StackLib)
};
