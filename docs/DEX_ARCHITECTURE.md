# DEX Architecture

This project is building a simplified Uniswap V2-style constant-product DEX with Solidity `^0.8.28`, Hardhat 3, TypeScript, and Solidity unit tests.

## Current Contract Layout

```text
contracts/
  core/
    DexFactory.sol
    DexPool.sol
  interfaces/
    IDexFactory.sol
    IDexPool.sol
    IERC20Minimal.sol
  libraries/
    DexMath.sol
    SafeTransferLib.sol
  errors/
    DexErrors.sol
  mocks/
    MockERC20.sol
```

## Core Responsibilities

`DexFactory` creates one canonical pool per token pair. It sorts token addresses, rejects invalid pairs, prevents duplicates, stores pool lookup in both token orders, and emits `PoolCreated`.

`DexPool` owns the AMM state for a single pair. It stores reserves, mints and burns LP tokens, executes swaps, enforces the fee-adjusted constant-product invariant, and emits `Mint`, `Burn`, `Swap`, and `Sync`.

`DexPool` is also the LP token for its pair, following the Uniswap V2-style design. This keeps LP accounting local to the pool.

`DexMath` contains pure reusable AMM helpers: token sorting, minimum, integer square root, quote, exact-input output, and exact-output input.

`SafeTransferLib` wraps ERC20 calls and accepts both standard tokens that return `true` and non-standard tokens that return no data.

`MockERC20` is test-only infrastructure. Production contracts must not depend on it.

## Security Notes

- Token pairs are normalized by address before pool creation.
- Zero addresses and identical token pairs are rejected.
- Duplicate pools are rejected.
- Pool state-changing token operations use a reentrancy lock.
- Swaps enforce the fee-adjusted constant-product invariant.
- Fee-on-transfer and rebasing tokens are not supported.
- There are no owner, admin, pause, upgrade, or fee-switch controls at this stage.

## Testing

Current Solidity unit tests cover:

- `DexMath`: token ordering, quote, sqrt, swap math, revert paths.
- `MockERC20`: mint, transfer, approve, transferFrom, events, revert paths.
- `DexFactory`: pool creation, duplicate prevention, token ordering, event correctness.
- `DexPool`: initial liquidity, additional liquidity, burn, swap, sync, reserve correctness, event correctness, invalid inputs.

Use:

```shell
npm.cmd run compile
npm.cmd run typecheck
npm.cmd test
```

On this Windows environment, Hardhat may occasionally hit a user-local compiler cache mutex when run inside the sandbox. Rerunning the same command outside the sandbox has been used to verify the project.

## Next Step

The next protocol component should be `DexRouter`.

Router responsibilities:

- user-facing add liquidity
- user-facing remove liquidity
- swap exact tokens for tokens
- deadline checks
- slippage checks
- pool lookup through `DexFactory`

The router must not become the source of truth. Pool reserves and token balances remain authoritative.
