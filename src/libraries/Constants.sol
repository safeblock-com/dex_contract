// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant FEE_MAX = 1_000_000;

uint256 constant E18 = 1e18;
uint256 constant E6 = 1e6;

// == TransientStorageFacetLibrary ==

// keccak256("callback.facet.storage")
bytes32 constant CALLBACK_FACET_STORAGE = 0x1248b983d56fa782b7a88ee11066fc0746058888ea550df970b9eea952d65dd1;

// keccak256("sender.facet.storage")
bytes32 constant SENDER_FACET_STORAGE = 0x289cc669fe96ce33e95427b15b06e5cf0e5e79eb9894ad468d456975ce05c198;

// keccak256("token.facet.storage")
bytes32 constant TOKEN_FACET_STORAGE = 0xc0abc52de3d4e570867f700eb5dfe2c039750b7f48720ee0d6152f3aa8676374;
bytes32 constant TOKEN_FACET_STORAGE_START = 0xc0abc52de3d4e570867f700eb5dfe2c039750b7f48720ee0d6152f3aa8676375;

uint256 constant FEE_PAID_FLAG = 0x010000000000000000000000000000000000000000;

uint256 constant UNRECORDED_TOKEN_MASK = 0x80000000;

// == FeeLibrary ==

// keccak256("feeContract.storage")
bytes32 constant FEE_CONTRACT_STORAGE = 0xde699227b1a7fb52a64c41a77682cef2fe2815e2a233a451b6c9f64b1abac291;

// == MultiswapRouterFacet ==

/// @dev mask for UniswapV3 pair designation
/// if `mask & pair == true`, the swap is performed using the UniswapV3 logic
uint256 constant UNISWAP_V3_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
/// @dev address mask: `mask & pair == address(pair)`
address constant ADDRESS_MASK = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
/// @dev fee mask: `mask & (pair >> 160) == fee in pair`
uint24 constant FEE_MASK = 0xffffff;

/// @dev minimum and maximum possible values of SQRT_RATIO in UniswapV3
uint160 constant MIN_SQRT_RATIO_PLUS_ONE = 4_295_128_740;
uint160 constant MAX_SQRT_RATIO_MINUS_ONE = 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_341;

/// @dev 2**255 - 1
uint256 constant CAST_INT_CONSTANT =
    57_896_044_618_658_097_711_785_492_504_343_953_926_634_992_332_820_282_019_728_792_003_956_564_819_967;
