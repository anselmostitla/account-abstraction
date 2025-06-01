// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { MinimalAccount } from "../../src/ethereum/MinimalAccount.sol";
import { DeployMinimalAccount } from "../../script/DeployMinimalAccount.s.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MinimalAccountTest is Test {
   MinimalAccount minimalAccount;
   HelperConfig helperConfig;
   ERC20Mock usdc;
   address randomUser = makeAddr("randomUser");

   uint256 constant AMOUNT = 1e18;

   function setUp() public {
      DeployMinimalAccount deployMinimalAccount = new DeployMinimalAccount();
      (helperConfig, minimalAccount) = deployMinimalAccount.deployMinimalAccount();
      usdc = new ERC20Mock();
   }

   // Test eoa -> minimalAccount
   function testOwnerCanExecuteCommands() public{
      // Arrange
      assertEq(usdc.balanceOf(address(minimalAccount)), 0);
      address dest = address(usdc);
      uint256 value = 0;
      bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, minimalAccount, AMOUNT);
      // Action
      vm.prank(minimalAccount.owner());
      minimalAccount.execute(dest, value, functionData);
      // Assert
      assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
   }

   function testNonOwnerCannotExecuteCommands(address fakeOwner) public {
      vm.assume(fakeOwner != minimalAccount.owner());
      // Arrange
      assertEq(usdc.balanceOf(address(minimalAccount)), 0);
      address dest = address(usdc);
      uint256 value = 0;
      bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, minimalAccount, AMOUNT);
      // Action
      vm.prank(fakeOwner);
      vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
      minimalAccount.execute(dest, value, functionData);

   }

}