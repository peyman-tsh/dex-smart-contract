// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Dex_ApprovalFailed, Dex_TransferFailed} from "../errors/DexErrors.sol";
import {IERC20Minimal} from "../interfaces/IERC20Minimal.sol";

/// @notice Safe ERC20 helpers that accept tokens returning no value or true.
library SafeTransferLib {
  /// @notice Transfers tokens and reverts if the token call fails or returns false.
  function safeTransfer(address token, address to, uint256 value) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeCall(IERC20Minimal.transfer, (to, value))
    );

    if (!success || !_didReturnTrue(data)) {
      revert Dex_TransferFailed();
    }
  }

  /// @notice Transfers tokens from an approved account and accepts non-returning ERC20s.
  function safeTransferFrom(address token, address from, address to, uint256 value) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeCall(IERC20Minimal.transferFrom, (from, to, value))
    );

    if (!success || !_didReturnTrue(data)) {
      revert Dex_TransferFailed();
    }
  }

  /// @notice Sets token allowance and reverts on failed or false-returning approvals.
  function safeApprove(address token, address spender, uint256 value) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeCall(IERC20Minimal.approve, (spender, value))
    );

    if (!success || !_didReturnTrue(data)) {
      revert Dex_ApprovalFailed();
    }
  }

  /// @dev ERC20 success is either no return data or ABI-encoded true.
  function _didReturnTrue(bytes memory data) private pure returns (bool) {
    return data.length == 0 || (data.length == 32 && abi.decode(data, (bool)));
  }
}
