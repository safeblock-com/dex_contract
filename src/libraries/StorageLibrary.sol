// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @dev Storage struct for the MultiswapRouterFacet.
///      Contains a cached pool address for Uniswap V3 swap callbacks.
struct MultiswapRouterFacetStorage {
    /// @dev Cached pool address for Uniswap V3 swap callbacks.
    ///      Set in `_swapUniV3ExactIn` and cleared in the `fallback` function after validation.
    address poolAddressCache;
    ///
    uint8 swapType; // 0 - multiswap, 1 - reverse multiswap
    ///
    uint8 pairsLength;
}

/// @notice Storage struct for the LayerZeroFacet.
/// @dev Stores trusted peers, gas limits, and default gas limit to manage cross-chain messaging.
struct LayerZeroFacetStorage {
    /// @notice Mapping of destination endpoint IDs to trusted peer addresses.
    /// @dev Stores the trusted peer (bytes32) for each remote chain’s endpoint ID. Defaults to `address(this)` if unset.
    mapping(uint32 eid => bytes32 peer) peers;
    /// @notice Mapping of destination endpoint IDs to gas limits.
    /// @dev Stores the gas limit for messages sent to each remote chain. Falls back to `defaultGasLimit` if unset.
    mapping(uint32 eid => uint128 gasLimit) gasLimitLookup;
    /// @notice The default gas limit for cross-chain messages.
    /// @dev Used when no specific gas limit is set for a destination endpoint ID.
    uint128 defaultGasLimit;
}

library StorageLibrary {
    // =========================
    // storage slots
    // =========================

    /// @dev Storage slot for the MultiswapRouterFacet to avoid collisions.
    ///      Computed as "uint256(keccak256("multiswap.router.storage")) - 1" to ensure a unique storage position.
    bytes32 private constant MULTISWAP_ROUTER_FACET_STORAGE =
        0x73a3a170c596aa083fa5166abc0f3239e53b41143f45c8bd25a602694c09d734;

    /// @dev Storage slot for the LayerZeroFacet to avoid collisions.
    ///      Computed as keccak256("layerZero.storage") to ensure a unique storage position.
    bytes32 private constant LAYERZERO_FACET_STORAGE =
        0x7f8156d470b4ca2c59b150cce6693dce9d231528b9e476a0fbfb17f10e0dab09;

    // =========================
    // storage getters
    // =========================

    /// @dev Retrieves the storage slot for the MultiswapRouterFacet.
    ///      Uses inline assembly to access the `MULTISWAP_ROUTER_FACET_STORAGE` slot.
    /// @return s The storage slot pointer for the MultiswapRouterFacet.
    function getMultiswapRouterFacetStorage() internal pure returns (MultiswapRouterFacetStorage storage s) {
        assembly ("memory-safe") {
            s.slot := MULTISWAP_ROUTER_FACET_STORAGE
        }
    }

    /// @dev Retrieves the storage slot for the LayerZeroFacet.
    ///      Uses inline assembly to access the `LAYERZERO_FACET_STORAGE` slot.
    /// @return s The storage slot pointer for the LayerZeroFacet.
    function getLayerZeroFacetStorage() internal pure returns (LayerZeroFacetStorage storage s) {
        assembly ("memory-safe") {
            s.slot := LAYERZERO_FACET_STORAGE
        }
    }
}
