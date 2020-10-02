// eslint-disable-next-line camelcase
async function deploySystem(deploy_list) {
  const deployed = {} // name: contract object
  const linkable = {} // name: linkable address

  // eslint-disable-next-line camelcase,guard-for-in
  for (const i in deploy_list) {
    await deploy_list[i].contract.detectNetwork()

    await deploy_list[i].contract.link(linkable)
    const contract = await deploy_list[i].contract.new()
    linkable[deploy_list[i].name] = contract.address
    deployed[deploy_list[i].name] = contract
  }
  return deployed
}

function range(n) {
  return [...Array(n).keys()]
}

const sumReducer = (a, b) => a + b

module.exports = {
  deploySystem: deploySystem,
  range: range,
  sumReducer: sumReducer,
}
