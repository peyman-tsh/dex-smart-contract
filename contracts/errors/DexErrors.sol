// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Shared protocol validation errors.
error Dex_ZeroAddress();
error Dex_IdenticalTokens();
error Dex_InsufficientAmount();
error Dex_InsufficientLiquidity();
error Dex_InsufficientInputAmount();
error Dex_InsufficientOutputAmount();
error Dex_InsufficientBalance();
error Dex_InsufficientAllowance();
error Dex_ExcessiveInputAmount();
error Dex_Expired();
error Dex_InvalidPath();
error Dex_InvalidRecipient();

// Factory/pool lookup errors.
error Dex_PoolExists();
error Dex_PoolNotFound();

// ERC20 interaction errors.
error Dex_TransferFailed();
error Dex_ApprovalFailed();

// Pool safety and invariant errors.
error Dex_KInvariant();
error Dex_Reentrancy();
