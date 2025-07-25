// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script, console2 } from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
   
   error HelperConfig__InvalidChainId();

   struct NetworkConfig {
      address entryPoint;
      address account;
   }

   uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
   uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 333;
   uint256 constant LOCAL_CHAIN_ID = 31337;
   address constant BURNER_WALLET = 0x4560f03A937eE6Fdb80b339A76d16ea4351F97A1;
   // address constant DEFAULT_SENDER_WALLET = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38; // I think this comes from Base.sol
   address constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

   NetworkConfig public localNetworkConfig;
   mapping(uint256 chainId => NetworkConfig) networkConfigs;

   constructor() {
      networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
   }

   function getConfig() public returns (NetworkConfig memory) {
      return getConfigByChainId(block.chainid);
   }

   function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory){
      if(chainId == LOCAL_CHAIN_ID){
         return getOrCreateAnvilEth();
      } else if(networkConfigs[chainId].entryPoint != address(0) ){
         return networkConfigs[chainId];
      } else {
         revert HelperConfig__InvalidChainId();
      }
   }

   function getEthSepoliaConfig() public pure returns(NetworkConfig memory){
      // 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
      return NetworkConfig ({entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032, account: BURNER_WALLET});
   }

   function getZkZyncSepoliaConfig() public pure returns (NetworkConfig memory){
      return NetworkConfig({entryPoint: address(0), account: BURNER_WALLET});
   }

   function getOrCreateAnvilEth() public returns(NetworkConfig memory) {
      if(localNetworkConfig.account != address(0)){
         return localNetworkConfig;
      }

      // Deploy mocks
      console2.log("Deploying mocks...");
      vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
      EntryPoint entryPoint = new EntryPoint();
      vm.stopBroadcast();

      localNetworkConfig = NetworkConfig({ entryPoint: address(entryPoint), account: ANVIL_DEFAULT_ACCOUNT});

      // Otherwise create a mock
      return localNetworkConfig;
   }
}