const {contract, web3} = require("@openzeppelin/test-environment")

const StackStub = contract.fromArtifact("StackStub")
const StackLib = contract.fromArtifact("StackLib")
const Branch = contract.fromArtifact("Branch")
const Position = contract.fromArtifact("Position")
const Leaf = contract.fromArtifact("Leaf")
const BN = web3.utils.BN
const utils = require("./helpers/utils")

const DEPLOY = [
  {name: "StackLib", contract: StackLib},
  {name: "Branch", contract: Branch},
  {name: "Position", contract: Position},
  {name: "Leaf", contract: Leaf},
  {name: "StackStub", contract: StackStub},
]

const chai = require("chai")
const assert = chai.assert

describe("Stack", () => {
  let deployed

  before(async () => {
    deployed = await utils.deploySystem(DEPLOY)
  })

  describe("Stack", async () => {
    it("correctly pushes and peeks values", async () => {
      await deployed.StackStub.stackPush(new BN(5))
      await deployed.StackStub.stackPush(new BN(4))
      await deployed.StackStub.stackPush(new BN(3))
      const size = await deployed.StackStub.getSize.call()

      const value = await deployed.StackStub.stackPeek.call()
      assert.equal(value, 3)
      assert.equal(size, 3)
    })

    it("correctly pops from stack", async () => {
      await deployed.StackStub.stackPush(new BN(2))
      await deployed.StackStub.stackPush(new BN(1))
      await deployed.StackStub.stackPop()
      const value = await deployed.StackStub.stackPeek.call()
      assert.equal(value, 2)
    })
  })
})
