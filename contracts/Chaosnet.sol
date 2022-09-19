pragma solidity 0.8.9;

/// @title Chaosnet
/// @notice This is a beta staker program for stakers willing to go the extra
/// mile with monitoring, share their logs with the dev team, and allow to more
/// carefully monitor the bootstrapping network. As the network matures, the
/// beta program will be ended.
contract Chaosnet {
  /// @notice Indicates if the chaosnet is active. The chaosnet is active
  /// after the contract deployment and can be ended with a call to
  /// `deactivateChaosnet()`. Once deactivated chaosnet can not be activated
  /// again.
  bool public isChaosnetActive;

  /// @notice Indicates if the given operator is a beta operator for chaosnet.
  mapping(address => bool) public isBetaOperator;

  /// @notice Address controlling chaosnet status and beta operator addresses.
  address public chaosnetMaestro;

  event BetaOperatorsAdded(address[] operators);

  event ChaosnetMaestroRoleTransferred(
    address oldChaosnetMaestro,
    address newChaosnetMaestro
  );

  event ChaosnetDeactivated();

  constructor() {
    _transferChaosnetMaestro(msg.sender);
    isChaosnetActive = true;
  }

  modifier onlyChaosnetMaestro() {
    require(msg.sender == chaosnetMaestro, "Not the chaosnet maestro");
    _;
  }

  /// @notice Adds beta operator to chaosnet. Can be called only by the
  /// chaosnet maestro.
  function addBetaOperators(address[] calldata operators)
    public
    onlyChaosnetMaestro
  {
    for (uint256 i = 0; i < operators.length; i++) {
      isBetaOperator[operators[i]] = true;
    }

    emit BetaOperatorsAdded(operators);
  }

  /// @notice Deactivates the chaosnet. Can be called only by the chaosnet
  /// maestro. Once deactivated chaosnet can not be activated again.
  function deactivateChaosnet() public onlyChaosnetMaestro {
    require(isChaosnetActive, "Chaosnet is not active");
    isChaosnetActive = false;
    emit ChaosnetDeactivated();
  }

  /// @notice Transfers the chaosnet maestro role to another non-zero address.
  function transferChaosnetMaestroRole(address newChaosnetMaestro)
    public
    onlyChaosnetMaestro
  {
    require(
      newChaosnetMaestro != address(0),
      "New chaosnet maestro must not be zero address"
    );
    _transferChaosnetMaestro(newChaosnetMaestro);
  }

  function _transferChaosnetMaestro(address newChaosnetMaestro) internal {
    address oldChaosnetMaestro = chaosnetMaestro;
    chaosnetMaestro = newChaosnetMaestro;
    emit ChaosnetMaestroRoleTransferred(oldChaosnetMaestro, newChaosnetMaestro);
  }
}
