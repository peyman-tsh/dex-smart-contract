// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDexPool {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

  function MINIMUM_LIQUIDITY() external pure returns (uint256);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function reserve0() external view returns (uint256);
  function reserve1() external view returns (uint256);
  function getReserves() external view returns (uint256 reserve0_, uint256 reserve1_);

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  function mint(address to) external returns (uint256 liquidity);
  function burn(address to) external returns (uint256 amount0, uint256 amount1);
  function swap(uint256 amount0Out, uint256 amount1Out, address to) external;
  function sync() external;
}
