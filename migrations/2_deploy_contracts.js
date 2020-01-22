const Sortition = artifacts.require("Sortition");
const Branch = artifacts.require("Branch");
const Position = artifacts.require("Position");
const StackLib = artifacts.require("StackLib");
const Trunk = artifacts.require("Trunk");
const Leaf = artifacts.require("Leaf");
const SortitionPool = artifacts.require("SortitionPool");


module.exports = function(deployer) {
    deployer.deploy(Branch);
    deployer.deploy(Position);
    deployer.deploy(StackLib);
    deployer.deploy(Trunk);
    deployer.link(Branch, Leaf);
    deployer.deploy(Leaf);
    deployer.link(Branch, Sortition);
    deployer.link(Position, Sortition);
    deployer.link(StackLib, Sortition);
    deployer.link(Trunk, Sortition);
    deployer.link(Leaf, Sortition);
    deployer.deploy(Sortition);
    deployer.link(Branch, SortitionPool);
    deployer.link(Position, SortitionPool);
    deployer.link(StackLib, SortitionPool);
    deployer.link(Trunk, SortitionPool);
    deployer.link(Leaf, SortitionPool);
    deployer.deploy(SortitionPool);
};
