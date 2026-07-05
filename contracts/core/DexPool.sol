// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
  Dex_IdenticalTokens,
  Dex_InsufficientAllowance,
  Dex_InsufficientBalance,
  Dex_InsufficientInputAmount,
  Dex_InsufficientLiquidity,
  Dex_InsufficientOutputAmount,
  Dex_InvalidRecipient,
  Dex_KInvariant,
  Dex_Reentrancy,
  Dex_ZeroAddress
} from "../errors/DexErrors.sol";
import {IDexPool} from "../interfaces/IDexPool.sol";
import {IERC20Minimal} from "../interfaces/IERC20Minimal.sol";
import {DexMath} from "../libraries/DexMath.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";

/// @notice Constant-product AMM pool that also acts as its own LP token.
contract DexPool is IDexPool {
  uint256 public constant MINIMUM_LIQUIDITY = 1_000;
  uint256 private constant FEE_DENOMINATOR = 1_000;
  uint256 private constant SWAP_FEE = 3;
  uint256 private constant UNLOCKED = 1;
  uint256 private constant LOCKED = 2;

  address public immutable factory;
  address public immutable token0;
  address public immutable token1;
  string public name = "Dex LP Token";
  string public symbol = "DLP";
  uint8 public constant decimals = 18;
  uint256 public reserve0;
  uint256 public reserve1;
  uint256 public totalSupply;

  mapping(address account => uint256 balance) public balanceOf;
  mapping(address owner => mapping(address spender => uint256 amount)) public allowance;

  uint256 private lockState = UNLOCKED;

  modifier lock() {
    if (lockState != UNLOCKED) {
      revert Dex_Reentrancy();
    }

    lockState = LOCKED;
    _;
    lockState = UNLOCKED;
  }

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

  function getReserves() external view returns (uint256 reserve0_, uint256 reserve1_) {
    reserve0_ = reserve0;
    reserve1_ = reserve1;
  }

  function transfer(address to, uint256 value) external returns (bool) {
    _transfer(msg.sender, to, value);

    return true;
  }

  function approve(address spender, uint256 value) external returns (bool) {
    if (spender == address(0)) {
      revert Dex_ZeroAddress();
    }

    allowance[msg.sender][spender] = value;

    emit Approval(msg.sender, spender, value);

    return true;
  }

  function transferFrom(address from, address to, uint256 value) external returns (bool) {
    uint256 allowed = allowance[from][msg.sender];

    if (allowed < value) {
      revert Dex_InsufficientAllowance();
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

  /// @notice Mints LP tokens after token0 and token1 have been transferred to the pool.
  function mint(address to) external lock returns (uint256 liquidity) {
    if (to == address(0)) {
      revert Dex_ZeroAddress();
    }

    (uint256 reserve0_, uint256 reserve1_) = (reserve0, reserve1);
    uint256 balance0 = IERC20Minimal(token0).balanceOf(address(this));
    uint256 balance1 = IERC20Minimal(token1).balanceOf(address(this));
    uint256 amount0 = balance0 - reserve0_;
    uint256 amount1 = balance1 - reserve1_;
    uint256 supply = totalSupply;

    if (supply == 0) {
      uint256 root = DexMath.sqrt(amount0 * amount1);

      if (root <= MINIMUM_LIQUIDITY) {
        revert Dex_InsufficientLiquidity();
      }

      liquidity = root - MINIMUM_LIQUIDITY;
      _mint(address(0), MINIMUM_LIQUIDITY);
    } else {
      liquidity = DexMath.min((amount0 * supply) / reserve0_, (amount1 * supply) / reserve1_);
    }

    if (liquidity == 0) {
      revert Dex_InsufficientLiquidity();
    }

    _mint(to, liquidity);

    emit Mint(msg.sender, to, amount0, amount1, liquidity);

    _update(balance0, balance1);
  }

  /// @notice Burns LP tokens held by the pool and transfers the underlying tokens to `to`.
  function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
    if (to == address(0)) {
      revert Dex_ZeroAddress();
    }

    uint256 liquidity = balanceOf[address(this)];

    if (liquidity == 0) {
      revert Dex_InsufficientLiquidity();
    }

    uint256 balance0 = IERC20Minimal(token0).balanceOf(address(this));
    uint256 balance1 = IERC20Minimal(token1).balanceOf(address(this));
    uint256 supply = totalSupply;

    amount0 = (liquidity * balance0) / supply;
    amount1 = (liquidity * balance1) / supply;

    if (amount0 == 0 || amount1 == 0) {
      revert Dex_InsufficientLiquidity();
    }

    _burn(address(this), liquidity);

    SafeTransferLib.safeTransfer(token0, to, amount0);
    SafeTransferLib.safeTransfer(token1, to, amount1);

    balance0 = IERC20Minimal(token0).balanceOf(address(this));
    balance1 = IERC20Minimal(token1).balanceOf(address(this));

    emit Burn(msg.sender, to, amount0, amount1, liquidity);

    _update(balance0, balance1);
  }

  /// @notice Swaps tokens after the caller has sent enough input token to the pool.
  function swap(uint256 amount0Out, uint256 amount1Out, address to) external lock {
    if (to == address(0) || to == token0 || to == token1) {
      revert Dex_InvalidRecipient();
    }

    if (amount0Out == 0 && amount1Out == 0) {
      revert Dex_InsufficientOutputAmount();
    }

    (uint256 reserve0_, uint256 reserve1_) = (reserve0, reserve1);

    if (amount0Out >= reserve0_ || amount1Out >= reserve1_) {
      revert Dex_InsufficientLiquidity();
    }

    if (amount0Out > 0) {
      SafeTransferLib.safeTransfer(token0, to, amount0Out);
    }
    if (amount1Out > 0) {
      SafeTransferLib.safeTransfer(token1, to, amount1Out);
    }

    uint256 balance0 = IERC20Minimal(token0).balanceOf(address(this));
    uint256 balance1 = IERC20Minimal(token1).balanceOf(address(this));
    uint256 amount0In = balance0 > reserve0_ - amount0Out ? balance0 - (reserve0_ - amount0Out) : 0;
    uint256 amount1In = balance1 > reserve1_ - amount1Out ? balance1 - (reserve1_ - amount1Out) : 0;

    if (amount0In == 0 && amount1In == 0) {
      revert Dex_InsufficientInputAmount();
    }

    uint256 balance0Adjusted = balance0 * FEE_DENOMINATOR - amount0In * SWAP_FEE;
    uint256 balance1Adjusted = balance1 * FEE_DENOMINATOR - amount1In * SWAP_FEE;

    if (balance0Adjusted * balance1Adjusted < reserve0_ * reserve1_ * FEE_DENOMINATOR ** 2) {
      revert Dex_KInvariant();
    }

    emit Swap(msg.sender, to, amount0In, amount1In, amount0Out, amount1Out);

    _update(balance0, balance1);
  }

  /// @notice Updates reserves to the current token balances. Rebasing tokens are not supported.
  function sync() external lock {
    _update(
      IERC20Minimal(token0).balanceOf(address(this)),
      IERC20Minimal(token1).balanceOf(address(this))
    );
  }

  function _transfer(address from, address to, uint256 value) private {
    if (from == address(0) || to == address(0)) {
      revert Dex_ZeroAddress();
    }

    uint256 balance = balanceOf[from];

    if (balance < value) {
      revert Dex_InsufficientBalance();
    }

    unchecked {
      balanceOf[from] = balance - value;
      balanceOf[to] += value;
    }

    emit Transfer(from, to, value);
  }

  function _mint(address to, uint256 value) private {
    totalSupply += value;
    balanceOf[to] += value;

    emit Transfer(address(0), to, value);
  }

  function _burn(address from, uint256 value) private {
    uint256 balance = balanceOf[from];

    if (balance < value) {
      revert Dex_InsufficientBalance();
    }

    unchecked {
      balanceOf[from] = balance - value;
      totalSupply -= value;
    }

    emit Transfer(from, address(0), value);
  }

  function _update(uint256 balance0, uint256 balance1) private {
    reserve0 = balance0;
    reserve1 = balance1;

    emit Sync(balance0, balance1);
  }
}
