// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// =========================
// General Constants
// =========================

/// @dev Maximum fee denominator for fee calculations.
uint256 constant FEE_MAX = 1_000_000;

/// @dev Represents 10^18, commonly used for token decimals (e.g., ETH, ERC20).
/// @dev Useful for arithmetic operations requiring high precision.
uint256 constant E18 = 1e18;

/// @dev Represents 10^6, used as swap fee denominator.
uint256 constant E6 = 1e6;

/// @dev Represents 2^96, used for sqrtPriceX96 calculations.
uint256 constant _2E96 = 2 ** 96;

// =========================
// TransientStorageFacetLibrary Constants
// =========================

/// @dev Storage slot for the callback address in `TransientStorageFacetLibrary`.
///      Computed as keccak256("callback.facet.storage"). Used in `getCallbackAddress` and `setCallbackAddress`.
bytes32 constant CALLBACK_FACET_STORAGE = 0x1248b983d56fa782b7a88ee11066fc0746058888ea550df970b9eea952d65dd1;

/// @dev Storage slot for the sender address in `TransientStorageFacetLibrary`.
///      Computed as keccak256("sender.facet.storage"). Used in `getSenderAddress`, `setSenderAddress`, and `isFeePaid`.
bytes32 constant SENDER_FACET_STORAGE = 0x289cc669fe96ce33e95427b15b06e5cf0e5e79eb9894ad468d456975ce05c198;

/// @dev Storage slot for the token index counter in `TransientStorageFacetLibrary`.
///      Computed as keccak256("token.facet.storage"). Tracks the number of recorded tokens in `setAmountForToken`.
bytes32 constant TOKEN_FACET_STORAGE = 0xc0abc52de3d4e570867f700eb5dfe2c039750b7f48720ee0d6152f3aa8676374;

/// @dev Starting storage slot for token addresses in `TransientStorageFacetLibrary`.
///      Computed as `TOKEN_FACET_STORAGE + 1`.
///      Stores token addresses in `setAmountForToken` and clears them in `getAmountForToken`.
bytes32 constant TOKEN_FACET_STORAGE_START = 0xc0abc52de3d4e570867f700eb5dfe2c039750b7f48720ee0d6152f3aa8676375;

/// @dev Flag indicating that a fee has been paid in `TransientStorageFacetLibrary`.
///      Used in `isFeePaid` to mark the fee status in the `SENDER_FACET_STORAGE` slot.
uint256 constant FEE_PAID_FLAG = 0x010000000000000000000000000000000000000000;

/// @dev Mask for unrecorded tokens in `TransientStorageFacetLibrary`.
///      Used in `setAmountForToken` to mark tokens that are not stored in the token array.
uint256 constant UNRECORDED_TOKEN_MASK = 0x80000000;

// =========================
// FeeLibrary Constants
// =========================

/// @dev Storage slot for the fee contract address and fee amount in `FeeLibrary`.
///      Computed as keccak256("feeContract.storage"). Used in `setFeeContractAddress` and `getFeeContractAddress`.
bytes32 constant FEE_CONTRACT_STORAGE = 0xde699227b1a7fb52a64c41a77682cef2fe2815e2a233a451b6c9f64b1abac291;

// =========================
// MultiswapRouterFacet Constants
// =========================

/// @dev Mask to designate a UniswapV3 pair in `MultiswapRouterFacet`.
///      If `pair & UNISWAP_V3_MASK` is true, the swap uses UniswapV3 logic.
uint256 constant UNISWAP_V3_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;

/// @dev Mask to extract the address of a pair in `MultiswapRouterFacet` and other contracts.
///      Used to isolate the lower 160 bits of an address (e.g., `pair & ADDRESS_MASK`).
address constant ADDRESS_MASK = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

/// @dev Mask to extract the fee from a pair in `MultiswapRouterFacet`.
///      Extracts the fee encoded in the upper bits of a pair (e.g., `(pair >> 160) & FEE_MASK`).
uint24 constant FEE_MASK = 0xffffff;

/// @dev Minimum sqrt price ratio plus one for UniswapV3 pools in `MultiswapRouterFacet`.
///      Represents the lower bound for valid sqrt price ratios in UniswapV3 swaps.
uint160 constant MIN_SQRT_RATIO_PLUS_ONE = 4_295_128_740;

/// @dev Maximum sqrt price ratio minus one for UniswapV3 pools in `MultiswapRouterFacet`.
///      Represents the upper bound for valid sqrt price ratios in UniswapV3 swaps.
uint160 constant MAX_SQRT_RATIO_MINUS_ONE = 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_341;

/// @dev Represents 2^255 - 1, used for safe integer casting in `MultiswapRouterFacet`.
///      Ensures safe arithmetic operations within the 256-bit integer range.
uint256 constant CAST_INT_CONSTANT =
    57_896_044_618_658_097_711_785_492_504_343_953_926_634_992_332_820_282_019_728_792_003_956_564_819_967;
