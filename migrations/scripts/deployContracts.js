// Deploys contracts using truffle artifacts and deployer.
module.exports = async function (artifacts, deployer) {
  const Sortition = artifacts.require("Sortition");
  const Branch = artifacts.require("Branch");
  const Position = artifacts.require("Position");
  const StackLib = artifacts.require("StackLib");
  const Trunk = artifacts.require("Trunk");
  const Leaf = artifacts.require("Leaf");
  const SortitionPoolFactory = artifacts.require("SortitionPoolFactory");

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

  await deployer.link(Branch, SortitionPoolFactory);
  await deployer.link(Position, SortitionPoolFactory);
  await deployer.link(StackLib, SortitionPoolFactory);
  await deployer.link(Trunk, SortitionPoolFactory);
  await deployer.link(Leaf, SortitionPoolFactory);
  await deployer.deploy(SortitionPoolFactory);
};
