// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title MultiswapRouterFacetStorage
/// @notice Storage layout for `MultiswapRouterFacet`.
/// @dev Contains temporary state during multiswap operations, including Uniswap V3 callback context.
///      This struct is used to manage storage for the MultiswapRouterFacet in a diamond proxy pattern.
struct MultiswapRouterFacetStorage {
    /// @notice Cached pool address for swap callback validation.
    address poolAddressCache;
    /// @notice Type of swap operation.
    /// @dev 0 = multiswap (standard forward swap), 1 = reverse multiswap.
    uint8 swapType;
    /// @notice Cached length of the pairs array used in a reverse multiswap.
    uint8 pairsLength;
    /// @notice Cached input token and amount for current swap path.
    /// @dev Packed as bytes32 for efficient passing between internal functions.
    bytes32 tokenAndAmount;
}

/// @title LayerZeroFacetStorage
/// @notice Storage layout for `LayerZeroFacet` used in cross-chain messaging.
/// @dev Manages trusted peers and gas configurations for each endpoint ID.
///      This struct is used to manage storage for the LayerZeroFacet in a diamond proxy pattern.
struct LayerZeroFacetStorage {
    /// @notice Mapping of LayerZero endpoint IDs to trusted peer addresses.
    /// @dev Each peer is stored as `bytes32` (typically address left-padded).
    ///      Defaults to `address(this)` if no trusted peer is explicitly set.
    mapping(uint32 eid => bytes32 peer) peers;
    /// @notice Gas limits per LayerZero endpoint.
    /// @dev If `gasLimitLookup[eid]` is unset, fallback to `defaultGasLimit`.
    mapping(uint32 eid => uint128 gasLimit) gasLimitLookup;
    /// @notice Fallback gas limit for endpoint IDs without a specific override.
    /// @dev Used in message dispatch to unknown or rarely used chains.
    uint128 defaultGasLimit;
    //
    mapping(uint32 eid => uint256) nonce;
    //
    mapping(address dstAddress => bytes32) userAndNonce;
}

/// @title StorageLibrary
/// @notice Provides access to unique storage slots for facets in a diamond architecture.
/// @dev Uses inline assembly to bind user-defined storage structs to fixed keccak256-based slots.
///      This library is used to manage storage in a diamond proxy pattern, ensuring each facet
///      has its own unique storage slot to prevent storage collisions.
library StorageLibrary {
    // =========================
    // Storage slot constants
    // =========================

    /// @dev Unique storage slot for `MultiswapRouterFacetStorage`.
    ///      Calculated as `uint256(keccak256("multiswap.router.storage")) - 1`.
    bytes32 private constant MULTISWAP_ROUTER_FACET_STORAGE =
        0x73a3a170c596aa083fa5166abc0f3239e53b41143f45c8bd25a602694c09d734;

    /// @dev Unique storage slot for `LayerZeroFacetStorage`.
    ///      Calculated as `keccak256("layerZero.storage")`.
    bytes32 private constant LAYER_ZERO_FACET_STORAGE =
        0x7f8156d470b4ca2c59b150cce6693dce9d231528b9e476a0fbfb17f10e0dab09;

    // =========================
    // Storage accessors
    // =========================

    /// @notice Returns a pointer to `MultiswapRouterFacetStorage`.
    /// @dev Performs an inline assembly assignment to access the predefined storage slot.
    /// @return s Storage reference to `MultiswapRouterFacetStorage`.
    function getMultiswapRouterFacetStorage() internal pure returns (MultiswapRouterFacetStorage storage s) {
        assembly ("memory-safe") {
            s.slot := MULTISWAP_ROUTER_FACET_STORAGE
        }
    }

    /// @notice Returns a pointer to `LayerZeroFacetStorage`.
    /// @dev Performs an inline assembly assignment to access the predefined storage slot.
    /// @return s Storage reference to `LayerZeroFacetStorage`.
    function getLayerZeroFacetStorage() internal pure returns (LayerZeroFacetStorage storage s) {
        assembly ("memory-safe") {
            s.slot := LAYER_ZERO_FACET_STORAGE
        }
    }
}
