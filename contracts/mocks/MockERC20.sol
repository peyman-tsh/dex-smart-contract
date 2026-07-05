// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20Minimal} from "../interfaces/IERC20Minimal.sol";

error MockERC20_ZeroAddress();
error MockERC20_InsufficientBalance();
error MockERC20_InsufficientAllowance();

/// @notice Simple mintable ERC20 token for local tests only.
contract MockERC20 is IERC20Minimal {
  // Mutable metadata keeps the mock simple and explicit for tests.
  string public name;
  string public symbol;
  uint8 public immutable decimals;
  uint256 public totalSupply;

  mapping(address account => uint256 balance) public balanceOf;
  mapping(address owner => mapping(address spender => uint256 amount)) public allowance;

  constructor(string memory name_, string memory symbol_, uint8 decimals_) {
    name = name_;
    symbol = symbol_;
    decimals = decimals_;
  }

  /// @notice Transfers mock tokens from the caller.
  function transfer(address to, uint256 value) external returns (bool) {
    _transfer(msg.sender, to, value);

    return true;
  }

  /// @notice Approves a spender for mock token transfers.
  function approve(address spender, uint256 value) external returns (bool) {
    if (spender == address(0)) {
      revert MockERC20_ZeroAddress();
    }

    allowance[msg.sender][spender] = value;

    emit Approval(msg.sender, spender, value);

    return true;
  }

  /// @notice Transfers mock tokens using allowance.
  function transferFrom(address from, address to, uint256 value) external returns (bool) {
    uint256 allowed = allowance[from][msg.sender];

    if (allowed < value) {
      revert MockERC20_InsufficientAllowance();
    }

    if (allowed != type(uint256).max) {
      unchecked {
        allowance[from][msg.sender] = allowed - value;
      }

      emit Approval(from, msg.sender, allowance[from][msg.sender]);
    }

    _transfer(from, to, value);

    return true;
  }

  /// @notice Mints mock tokens without access control for deterministic tests.
  function mint(address to, uint256 value) external {
    if (to == address(0)) {
      revert MockERC20_ZeroAddress();
    }

    totalSupply += value;
    balanceOf[to] += value;

    emit Transfer(address(0), to, value);
  }

  /// @dev Shared transfer implementation for direct and allowance-based transfers.
  function _transfer(address from, address to, uint256 value) private {
    if (to == address(0)) {
      revert MockERC20_ZeroAddress();
    }

    uint256 balance = balanceOf[from];

    if (balance < value) {
      revert MockERC20_InsufficientBalance();
    }

    unchecked {
      balanceOf[from] = balance - value;
      balanceOf[to] += value;
    }

    emit Transfer(from, to, value);
  }
}
