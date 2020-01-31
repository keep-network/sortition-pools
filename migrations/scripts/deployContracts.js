// Deploys contracts using truffle artifacts and deployer.
module.exports = async function (artifacts, deployer) {
  const Branch = artifacts.require("Branch");
  const Position = artifacts.require("Position");
  const StackLib = artifacts.require("StackLib");
  const Trunk = artifacts.require("Trunk");
  const Leaf = artifacts.require("Leaf");

  const SortitionPoolFactory = artifacts.require("SortitionPoolFactory");
  const BondedSortitionPoolFactory = artifacts.require("BondedSortitionPoolFactory");

  await deployer.deploy(Branch);
  await deployer.deploy(Position);
  await deployer.deploy(StackLib);
  await deployer.deploy(Trunk);
  await deployer.link(Branch, Leaf);
  await deployer.deploy(Leaf);

  // Sortition Pool Factory
  await deployer.link(Branch, SortitionPoolFactory);
  await deployer.link(Position, SortitionPoolFactory);
  await deployer.link(StackLib, SortitionPoolFactory);
  await deployer.link(Trunk, SortitionPoolFactory);
  await deployer.link(Leaf, SortitionPoolFactory);
  await deployer.deploy(SortitionPoolFactory);

  // Bonded Sortition Pool Factory
  await deployer.link(Branch, BondedSortitionPoolFactory);
  await deployer.link(Position, BondedSortitionPoolFactory);
  await deployer.link(StackLib, BondedSortitionPoolFactory);
  await deployer.link(Trunk, BondedSortitionPoolFactory);
  await deployer.link(Leaf, BondedSortitionPoolFactory);
  await deployer.deploy(BondedSortitionPoolFactory);
};
