// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {
  MockERC20,
  MockERC20_InsufficientAllowance,
  MockERC20_InsufficientBalance,
  MockERC20_ZeroAddress
} from "./MockERC20.sol";
import {IERC20Minimal} from "../interfaces/IERC20Minimal.sol";

/// @notice Unit tests for the local mintable ERC20 test token.
contract MockERC20Test is Test {
  MockERC20 private token;

  address private alice = address(0xA11CE);
  address private bob = address(0xB0B);
  address private spender = address(0x5EED);

  function setUp() public {
    // Fresh token per test keeps balances and allowances isolated.
    token = new MockERC20("Mock Token", "MOCK", 18);
  }

  function test_Constructor_SetsMetadata() public view {
    assertEq(token.name(), "Mock Token");
    assertEq(token.symbol(), "MOCK");
    assertEq(token.decimals(), 18);
  }

  function test_Mint_UpdatesSupplyAndBalanceAndEmitsTransfer() public {
    vm.expectEmit(true, true, false, true, address(token));
    emit IERC20Minimal.Transfer(address(0), alice, 100 ether);

    token.mint(alice, 100 ether);

    assertEq(token.totalSupply(), 100 ether);
    assertEq(token.balanceOf(alice), 100 ether);
  }

  function test_Mint_RevertsForZeroAddress() public {
    vm.expectRevert(MockERC20_ZeroAddress.selector);

    token.mint(address(0), 1 ether);
  }

  function test_Transfer_MovesBalanceAndEmitsTransfer() public {
    token.mint(alice, 100 ether);

    vm.prank(alice);
    vm.expectEmit(true, true, false, true, address(token));
    emit IERC20Minimal.Transfer(alice, bob, 40 ether);
    bool success = token.transfer(bob, 40 ether);

    assertTrue(success);
    assertEq(token.balanceOf(alice), 60 ether);
    assertEq(token.balanceOf(bob), 40 ether);
  }

  function test_Transfer_RevertsForInsufficientBalance() public {
    vm.prank(alice);
    vm.expectRevert(MockERC20_InsufficientBalance.selector);

    token.transfer(bob, 1 ether);
  }

  function test_Approve_SetsAllowanceAndEmitsApproval() public {
    vm.prank(alice);
    vm.expectEmit(true, true, false, true, address(token));
    emit IERC20Minimal.Approval(alice, spender, 25 ether);
    bool success = token.approve(spender, 25 ether);

    assertTrue(success);
    assertEq(token.allowance(alice, spender), 25 ether);
  }

  function test_Approve_RevertsForZeroSpender() public {
    vm.prank(alice);
    vm.expectRevert(MockERC20_ZeroAddress.selector);

    token.approve(address(0), 1 ether);
  }

  function test_TransferFrom_MovesBalanceAndReducesAllowance() public {
    token.mint(alice, 100 ether);

    vm.prank(alice);
    token.approve(spender, 75 ether);

    vm.prank(spender);
    bool success = token.transferFrom(alice, bob, 30 ether);

    assertTrue(success);
    assertEq(token.balanceOf(alice), 70 ether);
    assertEq(token.balanceOf(bob), 30 ether);
    assertEq(token.allowance(alice, spender), 45 ether);
  }

  function test_TransferFrom_DoesNotReduceMaxAllowance() public {
    token.mint(alice, 100 ether);

    vm.prank(alice);
    token.approve(spender, type(uint256).max);

    vm.prank(spender);
    token.transferFrom(alice, bob, 10 ether);

    assertEq(token.allowance(alice, spender), type(uint256).max);
  }

  function test_TransferFrom_RevertsForInsufficientAllowance() public {
    token.mint(alice, 100 ether);

    vm.prank(spender);
    vm.expectRevert(MockERC20_InsufficientAllowance.selector);

    token.transferFrom(alice, bob, 1 ether);
  }
}
