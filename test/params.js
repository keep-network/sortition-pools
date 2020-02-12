// Parameters for configuration

// How many bits a position uses per level of the tree;
// each branch of the tree contains 2**SLOTBITS slots.
const slotBits = 4
const levels = 5

const slotCount = 2 ** slotBits
const slotWidth = 2 ** (8 - slotBits)
const lastSlot = slotCount - 1
const slotMax = (2 ** slotWidth) - 1

const slotPointerMax = (2 ** slotBits) - 1
const positionBits = levels * slotBits
const positionMax = (2 ** positionBits) - 1
const leafFlag = 1 << positionBits

module.exports = {
  slotBits: slotBits,
  levels: levels,

  slotCount: slotCount,
  slotWidth: slotWidth,
  lastSlot: lastSlot,
  slotMax: slotMax,

  slotPointerMax: slotPointerMax,
  positionBits: positionBits,
  positionMax: positionMax,
  leafFlag: leafFlag,
}
