// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CallbackFacetLibrary
/// @dev library for store callback address
library CallbackFacetLibrary {
    // keccak("callback.facet.storage")
    bytes32 internal constant CALLBACK_FACET_STORAGE =
        0x1248b983d56fa782b7a88ee11066fc0746058888ea550df970b9eea952d65dd1;

    /// @notice get callback address
    /// @dev if callback address is not address(0) -> set callback address to address(0)
    function getCallbackAddress() internal returns (address callbackAddress) {
        assembly ("memory-safe") {
            callbackAddress := sload(CALLBACK_FACET_STORAGE)

            if callbackAddress { sstore(CALLBACK_FACET_STORAGE, 0) }
        }
    }

    /// @notice set callback address
    function setCallbackAddress(address callbackAddress) internal {
        assembly ("memory-safe") {
            sstore(CALLBACK_FACET_STORAGE, callbackAddress)
        }
    }
}
