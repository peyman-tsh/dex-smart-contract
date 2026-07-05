// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Dex_IdenticalTokens, Dex_ZeroAddress} from "../errors/DexErrors.sol";

/// @notice Minimal pool shell created by DexFactory. AMM logic is added in the pool phase.
contract DexPool {
  address public immutable factory;
  address public immutable token0;
  address public immutable token1;

  constructor(address token0_, address token1_) {
    if (token0_ == address(0) || token1_ == address(0)) {
      revert Dex_ZeroAddress();
    }

    if (token0_ >= token1_) {
      revert Dex_IdenticalTokens();
    }

    factory = msg.sender;
    token0 = token0_;
    token1 = token1_;
  }
}
