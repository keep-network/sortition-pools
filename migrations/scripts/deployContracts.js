// Deploys contracts using truffle artifacts and deployer.

async function deployLibraries(artifacts, deployer) {
  const Branch = artifacts.require('Branch')
  const Position = artifacts.require('Position')
  const StackLib = artifacts.require('StackLib')
  const Leaf = artifacts.require('Leaf')

  await deployer.deploy(Branch)
  await deployer.deploy(Position)
  await deployer.deploy(StackLib)
  await deployer.link(Branch, Leaf)
  await deployer.deploy(Leaf)
}

async function deploySortitionPoolFactory(artifacts, deployer) {
  await deployLibraries(artifacts, deployer)

  const Branch = artifacts.require('Branch')
  const Position = artifacts.require('Position')
  const StackLib = artifacts.require('StackLib')
  const Leaf = artifacts.require('Leaf')

  const SortitionPoolFactory = artifacts.require('SortitionPoolFactory')

  // Sortition Pool Factory
  await deployer.link(Branch, SortitionPoolFactory)
  await deployer.link(Position, SortitionPoolFactory)
  await deployer.link(StackLib, SortitionPoolFactory)
  await deployer.link(Leaf, SortitionPoolFactory)
  await deployer.deploy(SortitionPoolFactory)
};

async function deployBondedSortitionPoolFactory(artifacts, deployer) {
  await deployLibraries(artifacts, deployer)

  const Branch = artifacts.require('Branch')
  const Position = artifacts.require('Position')
  const StackLib = artifacts.require('StackLib')
  const Leaf = artifacts.require('Leaf')

  const BondedSortitionPoolFactory = artifacts.require('BondedSortitionPoolFactory')

  // Bonded Sortition Pool Factory
  await deployer.link(Branch, BondedSortitionPoolFactory)
  await deployer.link(Position, BondedSortitionPoolFactory)
  await deployer.link(StackLib, BondedSortitionPoolFactory)
  await deployer.link(Leaf, BondedSortitionPoolFactory)
  await deployer.deploy(BondedSortitionPoolFactory)
};

module.exports = {
  deploySortitionPoolFactory,
  deployBondedSortitionPoolFactory,
}
