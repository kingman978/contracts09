// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/**
 * @title AddressesProvider
 * @notice The Addresses Provider serves as a central storage of system internal and external
 *         contract addresses that change between deploys and across chains
 * @author Veliko Minkov <veliko@midascapital.xyz>
 */
contract AddressesProvider is OwnableUpgradeable {
  mapping(string => address) private _addresses;
  mapping(address => Contract) public flywheelRewards;
  mapping(address => Contract) public plugins;
  mapping(address => Contract) public redemptionStrategies;
  mapping(address => Contract) public fundingStrategies;
  mapping(address => JarvisPool) public jarvisPools;

  /// @dev Initializer to set the admin that can set and change contracts addresses
  function initialize(address owner) public initializer {
    __Ownable_init();
    _transferOwnership(owner);
  }

  event AddressSet(string id, address indexed newAddress);

  event ContractSet(address indexed key, string contractType, address contractAddress);

  /**
   * @dev The contract address and a string that uniquely identifies the contract's interface
   */
  struct Contract {
    address addr;
    string contractInterface;
  }

  struct JarvisPool {
    address syntheticToken;
    address collateralToken;
    address liquidityPool;
    uint256 expirationTime;
  }

  /**
   * @dev sets the address and contract interface ID of the flywheel for the reward token
   * @param rewardToken the reward token address
   * @param flywheelRewardsModule the flywheel rewards module address
   * @param contractInterface a string that uniquely identifies the contract's interface
   */
  function setFlywheelRewards(
    address rewardToken,
    address flywheelRewardsModule,
    string calldata contractInterface
  ) public onlyOwner {
    flywheelRewards[rewardToken] = Contract(flywheelRewardsModule, contractInterface);
    emit ContractSet(rewardToken, contractInterface, flywheelRewardsModule);
  }

  /**
   * @dev sets the address and contract interface ID of the ERC4626 plugin for the asset
   * @param asset the asset address
   * @param plugin the ERC4626 plugin address
   * @param contractInterface a string that uniquely identifies the contract's interface
   */
  function setPlugin(
    address asset,
    address plugin,
    string calldata contractInterface
  ) public onlyOwner {
    plugins[asset] = Contract(plugin, contractInterface);
    emit ContractSet(asset, contractInterface, plugin);
  }

  /**
   * @dev sets the address and contract interface ID of the redemption strategy for the asset
   * @param asset the asset address
   * @param strategy redemption strategy address
   * @param contractInterface a string that uniquely identifies the contract's interface
   */
  function setRedemptionStrategy(
    address asset,
    address strategy,
    string calldata contractInterface
  ) public onlyOwner {
    redemptionStrategies[asset] = Contract(strategy, contractInterface);
    emit ContractSet(asset, contractInterface, strategy);
  }

  /**
   * @dev sets the address and contract interface ID of the funding strategy for the asset
   * @param asset the asset address
   * @param strategy funding strategy address
   * @param contractInterface a string that uniquely identifies the contract's interface
   */
  function setFundingStrategy(
    address asset,
    address strategy,
    string calldata contractInterface
  ) public onlyOwner {
    fundingStrategies[asset] = Contract(strategy, contractInterface);
    emit ContractSet(asset, contractInterface, strategy);
  }

  /**
   * @dev configures the Jarvis pool of a Jarvis synthetic token
   * @param syntheticToken the synthetic token address
   * @param collateralToken the collateral token address
   * @param liquidityPool the liquidity pool address
   * @param expirationTime the operation expiration time
   */
  function setJarvisPool(
    address syntheticToken,
    address collateralToken,
    address liquidityPool,
    uint256 expirationTime
  ) public onlyOwner {
    jarvisPools[syntheticToken] = JarvisPool(syntheticToken, collateralToken, liquidityPool, expirationTime);
  }

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(string calldata id, address newAddress) external onlyOwner {
    _addresses[id] = newAddress;
    emit AddressSet(id, newAddress);
  }

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(string calldata id) public view returns (address) {
    return _addresses[id];
  }
}
