const Sortition = artifacts.require("Sortition");
const Branch = artifacts.require("Branch");
const Position = artifacts.require("Position");
const StackLib = artifacts.require("StackLib");


module.exports = function(deployer) {
    deployer.deploy(Branch);
    deployer.deploy(Position);
    deployer.deploy(StackLib);
    deployer.link(Branch, Sortition);
    deployer.link(Position, Sortition);
    deployer.link(StackLib, Sortition);
  deployer.deploy(Sortition);
};
