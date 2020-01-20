const Sortition = artifacts.require("Sortition");
const Branch = artifacts.require("Branch");
const Position = artifacts.require("Position");
const StackLib = artifacts.require("StackLib");
const Trunk = artifacts.require("Trunk");
const Leaf = artifacts.require("Leaf");
const SortitionPool = artifacts.require("SortitionPool");


module.exports = async function (deployer) {
  await deployer.deploy(Branch);
  await deployer.deploy(Position);
  await deployer.deploy(StackLib);
  await deployer.deploy(Trunk);
  await deployer.link(Branch, Leaf);
  await deployer.deploy(Leaf);
  await deployer.link(Branch, Sortition);
  await deployer.link(Position, Sortition);
  await deployer.link(StackLib, Sortition);
  await deployer.link(Trunk, Sortition);
  await deployer.link(Leaf, Sortition);
  await deployer.deploy(Sortition);
  await deployer.link(Branch, SortitionPool);
  await deployer.link(Position, SortitionPool);
  await deployer.link(StackLib, SortitionPool);
  await deployer.link(Trunk, SortitionPool);
  await deployer.link(Leaf, SortitionPool);
  await deployer.deploy(SortitionPool);
};
