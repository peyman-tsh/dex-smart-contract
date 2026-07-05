// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

/// @notice Starter contract kept as a Hardhat baseline while DEX contracts are built.
contract Counter {
  uint public x;

  event Increment(uint by);

  /// @notice Increments the counter by one.
  function inc() public {
    x++;
    emit Increment(1);
  }

  /// @notice Increments the counter by a positive amount.
  function incBy(uint by) public {
    require(by > 0, "incBy: increment should be positive");
    x += by;
    emit Increment(by);
  }
}
