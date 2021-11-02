// FIXME Retrieves past events. This is a workaround for a known issue described
// FIXME here: https://github.com/nomiclabs/hardhat/pull/1163
// FIXME The preferred way of getting events would be using listners:
// FIXME https://docs.ethers.io/v5/api/contract/contract/#Contract--events
function pastEvents(receipt, contract, eventName) {
  const events = []

  for (const log of receipt.logs) {
    if (log.address === contract.address) {
      const parsedLog = contract.interface.parseLog(log)
      if (parsedLog.name === eventName) {
        events.push(parsedLog)
      }
    }
  }

  return events
}

function range(n) {
  return [...Array(n).keys()]
}

const sumReducer = (a, b) => a + b

module.exports = {
  pastEvents: pastEvents,
  range: range,
  sumReducer: sumReducer,
}
