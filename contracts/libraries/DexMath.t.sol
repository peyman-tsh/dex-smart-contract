// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {
  Dex_IdenticalTokens,
  Dex_InsufficientAmount,
  Dex_InsufficientLiquidity,
  Dex_ZeroAddress
} from "../errors/DexErrors.sol";
import {DexMath} from "./DexMath.sol";

contract DexMathHarness {
  function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1) {
    return DexMath.sortTokens(tokenA, tokenB);
  }

  function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB) {
    return DexMath.quote(amountA, reserveA, reserveB);
  }

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut) {
    return DexMath.getAmountOut(amountIn, reserveIn, reserveOut);
  }
}

contract DexMathTest is Test {
  DexMathHarness private math;

  function setUp() public {
    math = new DexMathHarness();
  }

  function test_SortTokens_ReturnsDeterministicOrder() public pure {
    address tokenA = address(0x2000);
    address tokenB = address(0x1000);

    (address token0, address token1) = DexMath.sortTokens(tokenA, tokenB);

    assertEq(token0, tokenB);
    assertEq(token1, tokenA);
  }

  function test_SortTokens_RevertsForZeroAddress() public {
    vm.expectRevert(Dex_ZeroAddress.selector);

    math.sortTokens(address(0), address(0x1000));
  }

  function test_SortTokens_RevertsForIdenticalTokens() public {
    vm.expectRevert(Dex_IdenticalTokens.selector);

    math.sortTokens(address(0x1000), address(0x1000));
  }

  function test_Sqrt_RoundsDown() public pure {
    assertEq(DexMath.sqrt(0), 0);
    assertEq(DexMath.sqrt(1), 1);
    assertEq(DexMath.sqrt(4), 2);
    assertEq(DexMath.sqrt(15), 3);
    assertEq(DexMath.sqrt(16), 4);
  }

  function test_Quote_ReturnsProportionalAmount() public pure {
    assertEq(DexMath.quote(10 ether, 100 ether, 200 ether), 20 ether);
  }

  function test_Quote_RevertsForZeroAmount() public {
    vm.expectRevert(Dex_InsufficientAmount.selector);

    math.quote(0, 100 ether, 200 ether);
  }

  function test_GetAmountOut_AppliesSwapFee() public pure {
    assertEq(DexMath.getAmountOut(10 ether, 100 ether, 100 ether), 9066108938801491315);
  }

  function test_GetAmountIn_RoundsUp() public pure {
    assertEq(DexMath.getAmountIn(10 ether, 100 ether, 100 ether), 11144544745347152569);
  }

  function test_GetAmountOut_RevertsForEmptyLiquidity() public {
    vm.expectRevert(Dex_InsufficientLiquidity.selector);

    math.getAmountOut(1 ether, 0, 100 ether);
  }
}
