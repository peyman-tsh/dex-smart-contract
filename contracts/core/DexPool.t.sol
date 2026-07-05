// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {
  Dex_InsufficientInputAmount,
  Dex_InsufficientLiquidity,
  Dex_InsufficientOutputAmount,
  Dex_InvalidRecipient
} from "../errors/DexErrors.sol";
import {IDexPool} from "../interfaces/IDexPool.sol";
import {DexMath} from "../libraries/DexMath.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {DexFactory} from "./DexFactory.sol";
import {DexPool} from "./DexPool.sol";

contract DexPoolTest is Test {
  DexFactory private factory;
  MockERC20 private tokenA;
  MockERC20 private tokenB;
  DexPool private pool;

  address private alice = address(0xA11CE);
  address private bob = address(0xB0B);
  address private trader = address(0x7A0E);

  function setUp() public {
    factory = new DexFactory();
    tokenA = new MockERC20("Token A", "TKNA", 18);
    tokenB = new MockERC20("Token B", "TKNB", 18);
    pool = DexPool(factory.createPool(address(tokenA), address(tokenB)));
  }

  function test_MintInitialLiquidity_MintsLpAndUpdatesReserves() public {
    uint256 amount0 = 100 ether;
    uint256 amount1 = 400 ether;
    uint256 expectedLiquidity = DexMath.sqrt(amount0 * amount1) - pool.MINIMUM_LIQUIDITY();

    _fundPool(amount0, amount1);

    vm.expectEmit(true, true, false, true, address(pool));
    emit IDexPool.Transfer(address(0), address(0), pool.MINIMUM_LIQUIDITY());
    vm.expectEmit(true, true, false, true, address(pool));
    emit IDexPool.Transfer(address(0), alice, expectedLiquidity);
    vm.expectEmit(true, true, false, true, address(pool));
    emit IDexPool.Mint(address(this), alice, amount0, amount1, expectedLiquidity);
    vm.expectEmit(false, false, false, true, address(pool));
    emit IDexPool.Sync(amount0, amount1);

    uint256 liquidity = pool.mint(alice);

    assertEq(liquidity, expectedLiquidity);
    assertEq(pool.balanceOf(alice), expectedLiquidity);
    assertEq(pool.balanceOf(address(0)), pool.MINIMUM_LIQUIDITY());
    assertEq(pool.totalSupply(), DexMath.sqrt(amount0 * amount1));
    _assertReserves(amount0, amount1);
  }

  function test_MintAdditionalLiquidity_MintsProportionalLp() public {
    _addInitialLiquidity(alice, 100 ether, 400 ether);

    uint256 amount0 = 50 ether;
    uint256 amount1 = 200 ether;
    uint256 expectedLiquidity = DexMath.min(
      (amount0 * pool.totalSupply()) / pool.reserve0(),
      (amount1 * pool.totalSupply()) / pool.reserve1()
    );

    _fundPool(amount0, amount1);
    uint256 liquidity = pool.mint(bob);

    assertEq(liquidity, expectedLiquidity);
    assertEq(pool.balanceOf(bob), expectedLiquidity);
    _assertReserves(150 ether, 600 ether);
  }

  function test_MintInitialLiquidity_RevertsWhenTooSmall() public {
    _fundPool(1, 1);

    vm.expectRevert(Dex_InsufficientLiquidity.selector);

    pool.mint(alice);
  }

  function test_Burn_RemovesLiquidityAndUpdatesReserves() public {
    uint256 liquidity = _addInitialLiquidity(alice, 100 ether, 100 ether);
    uint256 burnLiquidity = liquidity / 2;
    uint256 expectedAmount0 = (burnLiquidity * 100 ether) / pool.totalSupply();
    uint256 expectedAmount1 = (burnLiquidity * 100 ether) / pool.totalSupply();

    vm.prank(alice);
    pool.transfer(address(pool), burnLiquidity);

    uint256 bobBalance0Before = _token0().balanceOf(bob);
    uint256 bobBalance1Before = _token1().balanceOf(bob);

    vm.expectEmit(true, true, false, true, address(pool));
    emit IDexPool.Burn(address(this), bob, expectedAmount0, expectedAmount1, burnLiquidity);

    (uint256 amount0, uint256 amount1) = pool.burn(bob);

    assertEq(amount0, expectedAmount0);
    assertEq(amount1, expectedAmount1);
    assertEq(_token0().balanceOf(bob), bobBalance0Before + expectedAmount0);
    assertEq(_token1().balanceOf(bob), bobBalance1Before + expectedAmount1);
    _assertReserves(100 ether - expectedAmount0, 100 ether - expectedAmount1);
  }

  function test_Burn_RevertsWhenNoLiquiditySentToPool() public {
    _addInitialLiquidity(alice, 100 ether, 100 ether);

    vm.expectRevert(Dex_InsufficientLiquidity.selector);

    pool.burn(bob);
  }

  function test_SwapExactInputForOutput_UpdatesBalancesReservesAndEvents() public {
    _addInitialLiquidity(alice, 100 ether, 100 ether);

    uint256 amountIn = 10 ether;
    uint256 expectedOut = DexMath.getAmountOut(amountIn, 100 ether, 100 ether);
    MockERC20 token0 = _token0();
    MockERC20 token1 = _token1();

    token0.mint(trader, amountIn);
    vm.prank(trader);
    token0.transfer(address(pool), amountIn);

    vm.expectEmit(true, true, false, true, address(pool));
    emit IDexPool.Swap(address(this), trader, amountIn, 0, 0, expectedOut);
    vm.expectEmit(false, false, false, true, address(pool));
    emit IDexPool.Sync(100 ether + amountIn, 100 ether - expectedOut);

    pool.swap(0, expectedOut, trader);

    assertEq(token1.balanceOf(trader), expectedOut);
    _assertReserves(100 ether + amountIn, 100 ether - expectedOut);
  }

  function test_Swap_RevertsForZeroOutput() public {
    _addInitialLiquidity(alice, 100 ether, 100 ether);

    vm.expectRevert(Dex_InsufficientOutputAmount.selector);

    pool.swap(0, 0, trader);
  }

  function test_Swap_RevertsForInvalidRecipient() public {
    _addInitialLiquidity(alice, 100 ether, 100 ether);
    address invalidRecipient = pool.token0();

    vm.expectRevert(Dex_InvalidRecipient.selector);

    pool.swap(0, 1 ether, invalidRecipient);
  }

  function test_Swap_RevertsForInsufficientLiquidity() public {
    _addInitialLiquidity(alice, 100 ether, 100 ether);

    vm.expectRevert(Dex_InsufficientLiquidity.selector);

    pool.swap(0, 100 ether, trader);
  }

  function test_Swap_RevertsWhenNoInputProvided() public {
    _addInitialLiquidity(alice, 100 ether, 100 ether);

    vm.expectRevert(Dex_InsufficientInputAmount.selector);

    pool.swap(0, 1 ether, trader);
  }

  function test_Sync_UpdatesReservesToBalances() public {
    _addInitialLiquidity(alice, 100 ether, 100 ether);
    _token0().mint(address(pool), 5 ether);

    vm.expectEmit(false, false, false, true, address(pool));
    emit IDexPool.Sync(105 ether, 100 ether);

    pool.sync();

    _assertReserves(105 ether, 100 ether);
  }

  function _addInitialLiquidity(
    address to,
    uint256 amount0,
    uint256 amount1
  ) private returns (uint256 liquidity) {
    _fundPool(amount0, amount1);
    liquidity = pool.mint(to);
  }

  function _fundPool(uint256 amount0, uint256 amount1) private {
    _token0().mint(address(this), amount0);
    _token1().mint(address(this), amount1);
    _token0().transfer(address(pool), amount0);
    _token1().transfer(address(pool), amount1);
  }

  function _assertReserves(uint256 expectedReserve0, uint256 expectedReserve1) private view {
    assertEq(pool.reserve0(), expectedReserve0);
    assertEq(pool.reserve1(), expectedReserve1);

    (uint256 reserve0, uint256 reserve1) = pool.getReserves();

    assertEq(reserve0, expectedReserve0);
    assertEq(reserve1, expectedReserve1);
  }

  function _token0() private view returns (MockERC20) {
    return MockERC20(pool.token0());
  }

  function _token1() private view returns (MockERC20) {
    return MockERC20(pool.token1());
  }
}
