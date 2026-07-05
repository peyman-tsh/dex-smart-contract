// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice AMM pool API. Each pool is also the LP ERC20 token for its pair.
interface IDexPool {
  // LP token events.
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  // AMM lifecycle events for backend/indexer consumption.
  event Mint(address indexed sender, address indexed to, uint256 amount0, uint256 amount1, uint256 liquidity);
  event Burn(address indexed sender, address indexed to, uint256 amount0, uint256 amount1, uint256 liquidity);
  event Swap(
    address indexed sender,
    address indexed to,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out
  );
  event Sync(uint256 reserve0, uint256 reserve1);

  /// @notice Permanently locked LP amount that prevents total supply from returning to zero.
  function MINIMUM_LIQUIDITY() external pure returns (uint256);
  /// @notice Factory that deployed the pool.
  function factory() external view returns (address);
  /// @notice Lower-address token in the pair.
  function token0() external view returns (address);
  /// @notice Higher-address token in the pair.
  function token1() external view returns (address);
  /// @notice Cached reserve for token0.
  function reserve0() external view returns (uint256);
  /// @notice Cached reserve for token1.
  function reserve1() external view returns (uint256);
  /// @notice Returns both cached reserves.
  function getReserves() external view returns (uint256 reserve0_, uint256 reserve1_);

  /// @notice LP token metadata name.
  function name() external view returns (string memory);
  /// @notice LP token metadata symbol.
  function symbol() external view returns (string memory);
  /// @notice LP token decimals.
  function decimals() external view returns (uint8);
  /// @notice Total LP token supply.
  function totalSupply() external view returns (uint256);
  /// @notice LP token balance for an account.
  function balanceOf(address account) external view returns (uint256);
  /// @notice LP token allowance.
  function allowance(address owner, address spender) external view returns (uint256);
  /// @notice Transfers LP tokens.
  function transfer(address to, uint256 value) external returns (bool);
  /// @notice Approves LP token allowance.
  function approve(address spender, uint256 value) external returns (bool);
  /// @notice Transfers LP tokens using allowance.
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  /// @notice Mints LP after the caller has transferred both tokens to the pool.
  function mint(address to) external returns (uint256 liquidity);
  /// @notice Burns LP held by the pool and sends underlying tokens to `to`.
  function burn(address to) external returns (uint256 amount0, uint256 amount1);
  /// @notice Sends output tokens to `to` after enough input has arrived.
  function swap(uint256 amount0Out, uint256 amount1Out, address to) external;
  /// @notice Updates cached reserves to current token balances.
  function sync() external;
}
