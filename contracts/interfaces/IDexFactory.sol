// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDexFactory {
  event PoolCreated(address indexed token0, address indexed token1, address indexed pool);

  function createPool(address tokenA, address tokenB) external returns (address pool);
  function getPool(address tokenA, address tokenB) external view returns (address pool);
  function allPools(uint256 index) external view returns (address pool);
  function allPoolsLength() external view returns (uint256);
}
