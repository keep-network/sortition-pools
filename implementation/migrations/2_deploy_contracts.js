const Sortition = artifacts.require("Sortition");
const Branch = artifacts.require("Branch");
const Position = artifacts.require("Position");
const StackLib = artifacts.require("StackLib");
const Trunk = artifacts.require("Trunk");


module.exports = function(deployer) {
    deployer.deploy(Branch);
    deployer.deploy(Position);
    deployer.deploy(StackLib);
    deployer.deploy(Trunk);
    deployer.link(Branch, Sortition);
    deployer.link(Position, Sortition);
    deployer.link(StackLib, Sortition);
    deployer.link(Trunk, Sortition);
  deployer.deploy(Sortition);
};
