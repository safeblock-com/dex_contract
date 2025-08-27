// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Constants
/// @notice A collection of constant values used throughout the protocol.
/// @dev Provides constant values for arithmetic operations, storage slots, bitmasks, and other utility values.
// =========================
// General Constants
// =========================

/// @dev Represents 10^18, commonly used for token decimals (e.g., ETH, ERC20).
/// @dev Useful for arithmetic operations requiring high precision.
uint256 constant E18 = 1e18;

/// @dev Represents 10^6, used as swap fee denominator.
uint256 constant E6 = 1e6;

/// @dev Represents 2^96, used for sqrtPriceX96 calculations.
uint256 constant _2E96 = 2 ** 96;

// =========================
// TransientStorageLibrary Constants
// =========================

/// @dev Storage slot for the callback address in `TransientStorageLibrary`.
///      Computed as keccak256("callback.facet.storage") - 1. Used in `getCallbackAddress` and `setCallbackAddress`.
bytes32 constant CALLBACK_FACET_STORAGE = 0x1248b983d56fa782b7a88ee11066fc0746058888ea550df970b9eea952d65dd0;

/// @dev Storage slot used to temporarily hold the sender address across internal calls.
///      Calculated as keccak256("sender.facet.storage") - 1.
bytes32 constant SENDER_FACET_STORAGE = 0x289cc669fe96ce33e95427b15b06e5cf0e5e79eb9894ad468d456975ce05c197;

/// @dev Storage slot used to temporarily hold the sender address across internal calls.
///      Calculated as keccak256("feeTokenAndAmount.facet.storage") - 1.
bytes32 constant FEE_TOKEN_AND_AMOUNT_FACET_STORAGE = 0x9c13ee85847e65d4779a4abcc83bdb760e20a0bde59fae75b7067e1808225b07;

// =========================
// FeeLibrary Constants
// =========================

/// @dev Storage slot for caching the fee recipient address and fee amount.
///      Packed as: (fee << 160) | address. Calculated as keccak256("feeContract.storage") - 1.
bytes32 constant FEE_CONTRACT_STORAGE = 0xde699227b1a7fb52a64c41a77682cef2fe2815e2a233a451b6c9f64b1abac290;

// =========================
// MultiswapRouterFacet Constants
// =========================

/// @dev Bitmask to detect if a pool is a UniswapV3-type pair.
///      Applied as: `if (pair & UNISWAP_V3_MASK != 0) => UniswapV3 logic`.
uint256 constant UNISWAP_V3_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;

/// @dev Bitmask to extract only the lower 160 bits from a bytes32-encoded address (standard EVM address size).
address constant ADDRESS_MASK = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

/// @dev Bitmask to extract the fee value (uint24) from an encoded pool value (bits 160–183).
uint24 constant FEE_MASK = 0xffffff;

/// @dev Minimum sqrt price ratio plus one. Used as the minimum bound in UniswapV3 swap calculations.
///      Corresponds to the smallest sqrtPriceX96 value + 1 allowed by the protocol.
uint160 constant MIN_SQRT_RATIO_PLUS_ONE = 4_295_128_740;

/// @dev Maximum sqrt price ratio minus one. Used as the maximum bound in UniswapV3 swap calculations.
///      Corresponds to the largest sqrtPriceX96 value - 1 allowed by the protocol.
uint160 constant MAX_SQRT_RATIO_MINUS_ONE = 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_341;

/// @dev Represents the maximum int256 value (2^255 - 1), used to safely cast uint256 to int256.
///      Used in UniswapV3 swap logic to ensure compatibility with `amountSpecified: int256`.
uint256 constant CAST_INT_CONSTANT =
    57_896_044_618_658_097_711_785_492_504_343_953_926_634_992_332_820_282_019_728_792_003_956_564_819_967;

/// @dev Bitmask to extract a 60-bit percentage field from packed data (commonly used in fee/routing logic).
uint256 constant PERCENTAGE_MASK = 0xfffffffffffffff;
