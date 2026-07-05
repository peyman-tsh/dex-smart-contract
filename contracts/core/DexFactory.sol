// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Dex_PoolExists} from "../errors/DexErrors.sol";
import {IDexFactory} from "../interfaces/IDexFactory.sol";
import {DexMath} from "../libraries/DexMath.sol";
import {DexPool} from "./DexPool.sol";

/// @notice Creates and indexes deterministic token-pair pools.
contract DexFactory is IDexFactory {
  mapping(address tokenA => mapping(address tokenB => address pool)) public getPool;
  address[] public allPools;

  function createPool(address tokenA, address tokenB) external returns (address pool) {
    (address token0, address token1) = DexMath.sortTokens(tokenA, tokenB);

    if (getPool[token0][token1] != address(0)) {
      revert Dex_PoolExists();
    }

    pool = address(new DexPool(token0, token1));

    getPool[token0][token1] = pool;
    getPool[token1][token0] = pool;
    allPools.push(pool);

    emit PoolCreated(token0, token1, pool);
  }

  function allPoolsLength() external view returns (uint256) {
    return allPools.length;
  }
}
