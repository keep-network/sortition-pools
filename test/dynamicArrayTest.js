describe("DynamicArray", () => {
  let testDynamicArray

  beforeEach(async () => {
    const TestDynamicArray = await ethers.getContractFactory("TestDynamicArray")
    testDynamicArray = await TestDynamicArray.deploy()
    await testDynamicArray.deployed()
  })

  describe("uintArray", async () => {
    it("runUintArrayTest", async () => {
      await testDynamicArray.runUintArrayTest()
      // ok, no revert
    })
  })

  describe("arrayPush", async () => {
    it("runArrayPushTest", async () => {
      await testDynamicArray.runArrayPushTest()
      // ok, no revert
    })
  })

  describe("arrayPop", async () => {
    it("runArrayPopTest", async () => {
      await testDynamicArray.runArrayPopTest()
      // ok, no revert
    })
  })
})
