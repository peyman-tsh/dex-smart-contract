// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice Factory API for creating and looking up token-pair pools.
interface IDexFactory {
  /// @notice Emitted once for each unique normalized token pair.
  event PoolCreated(address indexed token0, address indexed token1, address indexed pool);

  /// @notice Creates a pool for tokenA/tokenB after deterministic token sorting.
  function createPool(address tokenA, address tokenB) external returns (address pool);
  /// @notice Returns the pool for a pair in either token order.
  function getPool(address tokenA, address tokenB) external view returns (address pool);
  /// @notice Returns a pool by creation index.
  function allPools(uint256 index) external view returns (address pool);
  /// @notice Returns the number of pools created by the factory.
  function allPoolsLength() external view returns (uint256);
}
