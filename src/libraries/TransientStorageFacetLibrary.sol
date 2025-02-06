// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title TransientStorageFacetLibrary
/// @dev library for store transient data
library TransientStorageFacetLibrary {
    // keccak256("callback.facet.storage")
    bytes32 internal constant CALLBACK_FACET_STORAGE =
        0x1248b983d56fa782b7a88ee11066fc0746058888ea550df970b9eea952d65dd1;

    // keccak256("sender.facet.storage")
    bytes32 internal constant SENDER_FACET_STORAGE = 0x289cc669fe96ce33e95427b15b06e5cf0e5e79eb9894ad468d456975ce05c198;

    // keccak256("token.facet.storage")
    bytes32 internal constant TOKEN_FACET_STORAGE = 0xc0abc52de3d4e570867f700eb5dfe2c039750b7f48720ee0d6152f3aa8676374;

    uint256 internal constant FEE_PAID_FLAG = 0x010000000000000000000000000000000000000000;

    error TransientStorageFacetLibrary_InvalidSenderAddress();

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

    /// @notice get sender address
    function getSenderAddress() internal view returns (address senderAddress) {
        assembly ("memory-safe") {
            senderAddress := sload(SENDER_FACET_STORAGE)
        }

        if (senderAddress == address(0)) {
            revert TransientStorageFacetLibrary_InvalidSenderAddress();
        }
    }

    /// @notice get fee paid flag and set flag if fee not paid
    function isFeePaid() internal returns (bool _isFeePaid) {
        assembly ("memory-safe") {
            let value := sload(SENDER_FACET_STORAGE)

            _isFeePaid := shr(160, value)

            if and(gt(value, 0), iszero(_isFeePaid)) { sstore(SENDER_FACET_STORAGE, add(value, FEE_PAID_FLAG)) }
        }
    }

    /// @notice set sender address
    function setSenderAddress(address senderAddress) internal {
        assembly ("memory-safe") {
            sstore(SENDER_FACET_STORAGE, senderAddress)

            if iszero(senderAddress) { sstore(TOKEN_FACET_STORAGE, 0) }
        }
    }

    /// @notice set token address an amount which involved in multicall
    function setTokenAndAmount(address token, uint256 amount) internal {
        assembly ("memory-safe") {
            sstore(TOKEN_FACET_STORAGE, or(token, shl(160, amount)))
        }
    }

    /// @notice get token address an amount which involved in multicall
    function getTokenAndAmount() internal view returns (address token, uint256 amount) {
        assembly ("memory-safe") {
            token := sload(TOKEN_FACET_STORAGE)
            amount := shr(160, token)
        }
    }
}
