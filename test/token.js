const BN = web3.utils.BN

const tenMinimumUnits = new BN('10', 10)
const decimals = new BN('18', 10)
const oneKeepToken = tenMinimumUnits.pow(decimals)

function tokens(n) {
  return oneKeepToken.muln(n)
}

module.exports = {
  tokens: tokens,
}
