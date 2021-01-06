// Deploys contracts using truffle artifacts and deployer.
class SortitionPoolsDeployer {
  constructor(deployer, artifacts) {
    this.deployer = deployer
    this.artifacts = artifacts
    this.libs = {}
  }

  async deployLibraries() {
    if (!this.libs.Branch) {
      this.libs.Branch = this.artifacts.require("Branch")
      await this.deployer.deploy(this.libs.Branch)
    }

    if (!this.libs.Position) {
      this.libs.Position = this.artifacts.require("Position")
      await this.deployer.deploy(this.libs.Position)
    }

    if (!this.libs.StackLib) {
      this.libs.StackLib = this.artifacts.require("StackLib")
      await this.deployer.deploy(this.libs.StackLib)
    }

    if (!this.libs.Leaf) {
      this.libs.Leaf = this.artifacts.require("Leaf")
      await this.deployer.link(this.libs.Branch, this.libs.Leaf)
      await this.deployer.deploy(this.libs.Leaf)
    }
  }

  async deploySortitionPoolFactory() {
    await this.deployLibraries()

    const SortitionPoolFactory = this.artifacts.require("SortitionPoolFactory")

    // Sortition Pool Factory
    await this.deployer.link(this.libs.Branch, SortitionPoolFactory)
    await this.deployer.link(this.libs.Position, SortitionPoolFactory)
    await this.deployer.link(this.libs.StackLib, SortitionPoolFactory)
    await this.deployer.link(this.libs.Leaf, SortitionPoolFactory)
    await this.deployer.deploy(SortitionPoolFactory)
  }

  async deployBondedSortitionPoolFactory() {
    await this.deployLibraries()

    const BondedSortitionPoolFactory = this.artifacts.require(
      "BondedSortitionPoolFactory",
    )

    // Bonded Sortition Pool Factory
    await this.deployer.link(this.libs.Branch, BondedSortitionPoolFactory)
    await this.deployer.link(this.libs.Position, BondedSortitionPoolFactory)
    await this.deployer.link(this.libs.StackLib, BondedSortitionPoolFactory)
    await this.deployer.link(this.libs.Leaf, BondedSortitionPoolFactory)
    await this.deployer.deploy(BondedSortitionPoolFactory)
  }

  async deployFullyBackedSortitionPoolFactory() {
    await this.deployLibraries()

    const FullyBackedSortitionPoolFactory = this.artifacts.require(
      "FullyBackedSortitionPoolFactory",
    )

    // Fully Backed Sortition Pool Factory
    await this.deployer.link(this.libs.Branch, FullyBackedSortitionPoolFactory)
    await this.deployer.link(
      this.libs.Position,
      FullyBackedSortitionPoolFactory,
    )
    await this.deployer.link(
      this.libs.StackLib,
      FullyBackedSortitionPoolFactory,
    )
    await this.deployer.link(this.libs.Leaf, FullyBackedSortitionPoolFactory)
    await this.deployer.deploy(FullyBackedSortitionPoolFactory)
  }
}

module.exports = SortitionPoolsDeployer
