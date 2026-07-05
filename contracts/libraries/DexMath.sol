// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
  Dex_IdenticalTokens,
  Dex_InsufficientAmount,
  Dex_InsufficientLiquidity,
  Dex_ZeroAddress
} from "../errors/DexErrors.sol";

/// @notice Pure helpers for deterministic token ordering and constant-product AMM math.
library DexMath {
  uint256 internal constant FEE_DENOMINATOR = 1_000;
  uint256 internal constant DEFAULT_SWAP_FEE = 3;

  /// @notice Sorts a pair deterministically so pool addresses and lookups are stable.
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    if (tokenA == address(0) || tokenB == address(0)) {
      revert Dex_ZeroAddress();
    }

    if (tokenA == tokenB) {
      revert Dex_IdenticalTokens();
    }

    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  }

  /// @notice Returns the smaller of two unsigned integers.
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /// @notice Returns the integer square root, rounded down.
  function sqrt(uint256 value) internal pure returns (uint256 result) {
    if (value == 0) {
      return 0;
    }

    uint256 x = value;
    result = 1;

    // Build an initial power-of-two estimate before Newton iterations.
    if (x >= 2 ** 128) {
      x >>= 128;
      result <<= 64;
    }
    if (x >= 2 ** 64) {
      x >>= 64;
      result <<= 32;
    }
    if (x >= 2 ** 32) {
      x >>= 32;
      result <<= 16;
    }
    if (x >= 2 ** 16) {
      x >>= 16;
      result <<= 8;
    }
    if (x >= 2 ** 8) {
      x >>= 8;
      result <<= 4;
    }
    if (x >= 2 ** 4) {
      x >>= 4;
      result <<= 2;
    }
    if (x >= 2 ** 2) {
      result <<= 1;
    }

    // Seven iterations are enough to converge for uint256 after the estimate above.
    unchecked {
      result = (result + value / result) >> 1;
      result = (result + value / result) >> 1;
      result = (result + value / result) >> 1;
      result = (result + value / result) >> 1;
      result = (result + value / result) >> 1;
      result = (result + value / result) >> 1;
      result = (result + value / result) >> 1;

      uint256 roundedDown = value / result;
      return result < roundedDown ? result : roundedDown;
    }
  }

  /// @notice Quotes the proportional amountB for amountA at the current reserve ratio.
  function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
    if (amountA == 0) {
      revert Dex_InsufficientAmount();
    }

    if (reserveA == 0 || reserveB == 0) {
      revert Dex_InsufficientLiquidity();
    }

    amountB = (amountA * reserveB) / reserveA;
  }

  /// @notice Calculates output for an exact input swap with the default 0.3% fee.
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    if (amountIn == 0) {
      revert Dex_InsufficientAmount();
    }

    if (reserveIn == 0 || reserveOut == 0) {
      revert Dex_InsufficientLiquidity();
    }

    uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - DEFAULT_SWAP_FEE);
    uint256 numerator = amountInWithFee * reserveOut;
    uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;

    amountOut = numerator / denominator;
  }

  /// @notice Calculates required input for an exact output swap, rounded up.
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    if (amountOut == 0) {
      revert Dex_InsufficientAmount();
    }

    if (reserveIn == 0 || reserveOut == 0 || amountOut >= reserveOut) {
      revert Dex_InsufficientLiquidity();
    }

    uint256 numerator = reserveIn * amountOut * FEE_DENOMINATOR;
    uint256 denominator = (reserveOut - amountOut) * (FEE_DENOMINATOR - DEFAULT_SWAP_FEE);

    amountIn = numerator / denominator + 1;
  }
}
