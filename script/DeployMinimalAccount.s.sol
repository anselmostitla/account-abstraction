// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script, console2 } from "forge-std/Script.sol";
import { MinimalAccount } from "../src/ethereum/MinimalAccount.sol";
import { HelperConfig } from "./HelperConfig.s.sol";


contract DeployMinimalAccount is Script {
   function run() public {
      deployMinimalAccount();
   }

   function deployMinimalAccount() public returns(HelperConfig, MinimalAccount){
      HelperConfig helperConfig = new HelperConfig();
      HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

      vm.startBroadcast(config.account);
      MinimalAccount minimalAccount = new MinimalAccount(config.entryPoint);
      minimalAccount.transferOwnership(config.account);
      vm.stopBroadcast();

      console2.log(address(minimalAccount));
      return (helperConfig, minimalAccount);
   }
}