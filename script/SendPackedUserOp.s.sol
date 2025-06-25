// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MinimalAccount} from "../src/ethereum/MinimalAccount.sol";

contract SendPackedUserOp is Script {
   using MessageHashUtils for bytes32;

   function run() public {
      HelperConfig helperConfig = new HelperConfig();
      address dest = 0x65aFADD39029741B3b8f0756952C74678c9cEC93;
      uint256 value = 0;
      address oneOfMyAddress = 0x4560f03A937eE6Fdb80b339A76d16ea4351F97A1;
      uint256 amount = 1e18;
      bytes memory functionData = abi.encodeWithSelector(IERC20.approve.selector, oneOfMyAddress, amount);
      bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
      // 0xaE985E41DeDB73D0C4aBE015f5F6f2d9a7e5b5d8 comes from broadcast/DeployMinimalAccount.s.sol/11155111/run-latest.json
      PackedUserOperation memory userOp = generateSignedUserOperation(executeCallData, helperConfig.getConfig(), 0xaE985E41DeDB73D0C4aBE015f5F6f2d9a7e5b5d8);
      PackedUserOperation[] memory ops = new PackedUserOperation[](1);
      ops[0] = userOp;

      vm.startBroadcast();
      IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(helperConfig.getConfig().account));
      vm.stopBroadcast();
   }

   function generateSignedUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory config, address minimalAccount) public view returns(PackedUserOperation memory){
      // 1. Generate the unsigned data
      uint256 nonce = vm.getNonce(minimalAccount)-1;
      PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);
      
      // 2 Get the userOp hash
      bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
      bytes32 digest = userOpHash.toEthSignedMessageHash();
      
      // 3. Sign it, and return it
      uint8 v; bytes32 r; bytes32 s;
      uint256 SEPOLIA_PRIVATE_KEY = vm.envUint("SEPOLIA_PRIVATE_KEY");

      if(block.chainid == 31337){
         uint256 ANVIL_DEFAULT_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
         (v, r, s) = vm.sign(ANVIL_DEFAULT_PRIVATE_KEY, digest);
      } else {
         (v, r, s) = vm.sign(SEPOLIA_PRIVATE_KEY, digest);
      }
      
      userOp.signature = abi.encodePacked(r, s, v); // Pay attention to the order of rsv here
      return userOp;
   }

   function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce) internal pure returns(PackedUserOperation memory) {
      uint128 verificationGasLimit = 16777216;
      uint128 callGasLimit = verificationGasLimit;
      uint128 maxPriorityFeePerGas = 256;
      uint128 maxFeePerGas = maxPriorityFeePerGas;
      return PackedUserOperation({
         sender: sender,
         nonce:nonce,
         initCode: hex"",
         callData: callData,
         accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
         preVerificationGas: verificationGasLimit,
         gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
         paymasterAndData: hex"",
         signature: hex""
      });
   }
}