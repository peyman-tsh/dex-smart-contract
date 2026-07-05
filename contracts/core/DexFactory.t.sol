// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Dex_IdenticalTokens, Dex_PoolExists, Dex_ZeroAddress} from "../errors/DexErrors.sol";
import {IDexFactory} from "../interfaces/IDexFactory.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {DexFactory} from "./DexFactory.sol";
import {DexPool} from "./DexPool.sol";

/// @notice Unit tests for deterministic pool creation and lookup.
contract DexFactoryTest is Test {
  DexFactory private factory;
  MockERC20 private tokenA;
  MockERC20 private tokenB;

  function setUp() public {
    // Each test starts with a fresh factory and token pair.
    factory = new DexFactory();
    tokenA = new MockERC20("Token A", "TKNA", 18);
    tokenB = new MockERC20("Token B", "TKNB", 18);
  }

  function test_CreatePool_CreatesPoolAndStoresLookupBothDirections() public {
    (address token0, address token1) = _sort(address(tokenA), address(tokenB));

    address pool = factory.createPool(address(tokenA), address(tokenB));

    assertTrue(pool != address(0));
    assertEq(factory.getPool(address(tokenA), address(tokenB)), pool);
    assertEq(factory.getPool(address(tokenB), address(tokenA)), pool);
    assertEq(factory.allPools(0), pool);
    assertEq(factory.allPoolsLength(), 1);
    assertEq(DexPool(pool).factory(), address(factory));
    assertEq(DexPool(pool).token0(), token0);
    assertEq(DexPool(pool).token1(), token1);
  }

  function test_CreatePool_NormalizesTokenOrdering() public {
    (address token0, address token1) = _sort(address(tokenA), address(tokenB));

    address pool = factory.createPool(address(tokenB), address(tokenA));

    assertEq(DexPool(pool).token0(), token0);
    assertEq(DexPool(pool).token1(), token1);
  }

  function test_CreatePool_EmitsPoolCreatedEvent() public {
    (address token0, address token1) = _sort(address(tokenA), address(tokenB));

    vm.recordLogs();
    address pool = factory.createPool(address(tokenA), address(tokenB));
    Vm.Log[] memory entries = vm.getRecordedLogs();

    assertEq(entries.length, 1);
    assertEq(entries[0].emitter, address(factory));
    assertEq(entries[0].topics.length, 4);
    assertEq(entries[0].topics[0], IDexFactory.PoolCreated.selector);
    assertEq(entries[0].topics[1], _topicForAddress(token0));
    assertEq(entries[0].topics[2], _topicForAddress(token1));
    assertEq(entries[0].topics[3], _topicForAddress(pool));
    assertEq(entries[0].data.length, 0);
  }

  function test_CreatePool_RevertsWhenPoolExists() public {
    factory.createPool(address(tokenA), address(tokenB));

    vm.expectRevert(Dex_PoolExists.selector);

    factory.createPool(address(tokenB), address(tokenA));
  }

  function test_CreatePool_RevertsForZeroAddress() public {
    vm.expectRevert(Dex_ZeroAddress.selector);

    factory.createPool(address(0), address(tokenB));
  }

  function test_CreatePool_RevertsForIdenticalTokens() public {
    vm.expectRevert(Dex_IdenticalTokens.selector);

    factory.createPool(address(tokenA), address(tokenA));
  }

  function _sort(address tokenA_, address tokenB_) private pure returns (address token0, address token1) {
    (token0, token1) = tokenA_ < tokenB_ ? (tokenA_, tokenB_) : (tokenB_, tokenA_);
  }

  /// @dev Converts an address to the indexed-event topic encoding.
  function _topicForAddress(address value) private pure returns (bytes32) {
    return bytes32(uint256(uint160(value)));
  }
}
