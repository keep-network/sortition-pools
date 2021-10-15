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
    await this.deployer.link(this.libs.Leaf, SortitionPoolFactory)
    await this.deployer.deploy(SortitionPoolFactory)
  }
}

module.exports = SortitionPoolsDeployer
