pragma solidity ^0.5.10;

import "./Sortition.sol";
import "./RNG.sol";

/// @title A third party Bonding Contract providing information to the pool
/// about operator's eligibility for work selection.
interface BondingContract {

    /// @notice Function checks if the provided operator is eligible for work
    /// selection given the bonding requirements.
    ///
    /// The function returns true if the actual staker weight of the operator is
    /// equal or greater than the weight in the argument, and the operator is
    /// eligible for work selection from that pool, and any bond required can
    /// be created.
    ///
    /// The function returning false due to the operator not being eligble for
    /// work selection, the provided weight exceeds its actual staker weight, or
    /// any required bond is not possible to be created.
    ///
    /// Operators for which this function returns false are removed from the
    /// pool and not taken into account for work selection.
    function isEligible(
        address operator,
        uint stakingWeight,
        uint bondSize
    ) external returns (bool);
}


/// @title Bonded Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed and bonding requirements.
contract BondedSortitionPool is Sortition {
    event Group(address[] members);

    address[] group;

    function getSetGroup() public view returns (address[] memory) {
      return group;
    }

    function clearSetGroup() public {
      for (uint i = 0; i < group.length; i++) {
        group[i] = address(0);
      }
    }

    function selectSetGroupB(
      uint256 groupSize,
      bytes32 seed,
      uint bondSize,
      BondingContract bondingContract
    ) public returns (address[] memory) {
      uint operatorsRemaining = operatorsInPool();

      address[] memory selected = new address[](groupSize);
      uint nSelected = 0;

      uint idx;
      bytes32 rngState = seed;

      uint totalWeight = root.sumWeight();

      uint leafOrWeight;
      address op;
      bool duplicate;

      while (nSelected < groupSize) {
        require(operatorsRemaining >= groupSize, "Not enough operators in pool");

        (idx, rngState) = RNG.getIndex(totalWeight, rngState);
        /* (idx, rngState) = RNG.getIndex(root.sumWeight(), rngState); */

        leafOrWeight = leaves[pickWeightedLeaf(idx)];
        op = leafOrWeight.operator();
        // XXX: awful but saves a slot
        leafOrWeight = leafOrWeight.weight();

        duplicate = false;
        for (uint i = 0; i < nSelected; i++) {
          if (op == selected[i]) {
            duplicate = true;
            break;
          }
        }

        if (!duplicate) {
          if (bondingContract.isEligible(op, leafOrWeight, bondSize)) {
            selected[nSelected] = op;
            nSelected += 1;
          } else {
            removeOperator(op);
            totalWeight -= leafOrWeight;
            operatorsRemaining -= 1;
          }
        }
      }

      group = selected;
      return selected;
    }

    /// @notice Selects a new group of operators of the provided size based on
    /// the provided pseudo-random seed and bonding requirements. All operators
    /// in the group are unique.
    ///
    /// If there are not enough operators in a pool to form a group or not
    /// enough operators are eligible for work selection given the bonding
    /// requirements, the function fails.
    /// @param groupSize Size of the requested group
    /// @param seed Pseudo-random number used to select operators to group
    /// @param bondSize Size of the requested bond per operator
    /// @param bondingContract 3rd party contract checking bond requirements
    function selectSetGroup(
        uint256 groupSize,
        bytes32 seed,
        uint bondSize,
        BondingContract bondingContract
    ) public returns (address[] memory) {
        require(operatorsInPool() >= groupSize, "Not enough operators in pool");

        address[] memory selected = new address[](groupSize);
        uint nSelected = 0;

        RNG.IndexWeight[] memory selectedLeaves = new RNG.IndexWeight[](groupSize);
        uint selectedTotalWeight = 0;

        uint leaf;
        uint tempIdx;

        /* RNG.IndexWeight memory tempIW = new RNG.IndexWeight(0, 0); */

        bytes32 rngState = seed;

        /* loop */
        while (nSelected < groupSize) {
          require(
            root.sumWeight() > selectedTotalWeight,
            "Not enough operators in pool"
          );

          (tempIdx, rngState) = RNG.getUniqueIndex(
            root.sumWeight(),
            rngState,
            selectedLeaves,
            selectedTotalWeight
          );

          // XXX: cursed be lack of newtypes
          // on the upside, I can reuse the same variable slot for this
          // but seriously, this is the worst
          (leaf, tempIdx) = pickWeightedLeafWithIndex(tempIdx);
          leaf = leaves[leaf];

          address op = leaf.operator();
          uint wt = leaf.weight();

          /* tempIW.weight = leaf.weight(); */
          /* tempIW.index = tempIdx; */

          // Good operators go into the group and the list to skip,
          // naughty operators go onto the deletion list
          if (bondingContract.isEligible(op, wt, bondSize)) {

            // We insert the new index and weight into the lists,
            // keeping them both ordered by the starting indices.
            // To do this, we start by holding the new element outside the list.
            RNG.IndexWeight memory tempIW = RNG.IndexWeight(tempIdx, wt);

            for (uint i = 0; i < nSelected; i++) {
              RNG.IndexWeight memory thisIW = selectedLeaves[i];
              // With each element of the list,
              // we check if the outside element should go before it.
              // If true, we swap that element and the outside element.
              if (tempIW.index < thisIW.index) {
                selectedLeaves[i] = RNG.IndexWeight(tempIW.index, tempIW.weight);
                tempIW = thisIW;
              }
            }

            // Now the outside element is the last one,
            // so we push it to the end of the list.
            selectedLeaves[nSelected] = tempIW;

            // And increase the skipped weight.
            selectedTotalWeight += wt;

            selected[nSelected] = op;
            nSelected += 1;
          } else {
            removeOperator(op);

            // INLINE RNG.remapIndices()
            for (uint i = 0; i < nSelected; i++) {
              if (selectedLeaves[i].index > tempIdx) {
                selectedLeaves[i] = RNG.IndexWeight(
                  selectedLeaves[i].index - wt,
                  selectedLeaves[i].weight
                );
              }
            }
          }
        }
        /* pool */

        // If nothing has exploded by now,
        // we should have the correct size of group.

        group = selected;
        return selected;
    }
}
