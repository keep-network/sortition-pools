pragma solidity ^0.5.10;

import '../../contracts/Sortition.sol';

contract SortitionStub {
  using Sortition for Sortition.SortitionPool;

  Sortition.SortitionPool thePool;

  function initialize() public {
    uint[16] memory rLeaves;
    uint256[][16] memory emptyLeaves;
    thePool = Sortition.SortitionPool(0, rLeaves, emptyLeaves);
    thePool.initializeTrunks();
  }

  function setLeaf(uint position, uint theLeaf) public {
    thePool.setLeaf(position, theLeaf);
  }

  function toLeaf(address op, uint weight) public returns (uint) {
    return Sortition.toLeaf(op, weight);
  }

  function getLeaf(uint position) public view returns (uint) {
    thePool.getLeaf(position);
  }

  function getRoot() public returns (uint) {
    return thePool.getRoot();
  }

  function insert(address op, uint weight) public {
    thePool.insert(op, weight);
  }

  function removeLeaf(uint position) public {
    thePool.removeLeaf(position);
  }

  function removeOperator(address op) public {
    thePool.removeOperator(op);
  }

  function getFlaggedOperatorLeaf(address op) public view returns (uint) {
    return thePool.getFlaggedOperatorLeaf(op);
  }

  function updateLeaf(uint position, uint weight) public {
    thePool.updateLeaf(position, weight);
  }

  function pickWeightedLeaf(uint i) public view returns (uint) {
    return thePool.pickWeightedLeaf(i);
  }

  function leafAddress(uint leaf) public pure returns (address) {
    return Sortition.leafAddress(leaf);
  }
}
