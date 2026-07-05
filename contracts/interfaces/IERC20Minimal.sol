// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice Minimal ERC20 surface required by the DEX contracts.
interface IERC20Minimal {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /// @notice Human-readable token name.
  function name() external view returns (string memory);
  /// @notice Human-readable token symbol.
  function symbol() external view returns (string memory);
  /// @notice Number of decimal places used for display.
  function decimals() external view returns (uint8);
  /// @notice Total minted supply.
  function totalSupply() external view returns (uint256);
  /// @notice Token balance for an account.
  function balanceOf(address account) external view returns (uint256);
  /// @notice Remaining allowance from owner to spender.
  function allowance(address owner, address spender) external view returns (uint256);
  /// @notice Transfers tokens from the caller to `to`.
  function transfer(address to, uint256 value) external returns (bool);
  /// @notice Sets allowance from the caller to `spender`.
  function approve(address spender, uint256 value) external returns (bool);
  /// @notice Transfers tokens using an allowance granted by `from`.
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}
