// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    UNRECORDED_TOKEN_MASK,
    CALLBACK_FACET_STORAGE,
    SENDER_FACET_STORAGE,
    FEE_PAID_FLAG,
    TOKEN_FACET_STORAGE,
    TOKEN_FACET_STORAGE_START
} from "./Constants.sol";

/// @title TransientStorageFacetLibrary
/// @dev library for store transient data
library TransientStorageFacetLibrary {
    // =========================
    // errors
    // =========================

    /// @notice Throws when token not transferred from this contract after call
    error TokenNotTransferredFromContract();

    /// @notice Throws if `sender` is address(0)
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

            if iszero(senderAddress) {
                for {
                    let tokenIndex := sload(TOKEN_FACET_STORAGE)
                    sstore(TOKEN_FACET_STORAGE, 0)

                    let start := TOKEN_FACET_STORAGE_START
                } tokenIndex {
                    start := add(start, 1)
                    tokenIndex := sub(tokenIndex, 1)
                } {
                    if sload(start) {
                        // TokenNotTransferredFromContract()
                        mstore(0, 0xc26d3d6a)
                        revert(28, 4)
                    }
                }
            }
        }
    }

    /// @notice set token address an amount which involved in multicall
    function setAmountForToken(address token, uint256 amount, bool record) internal {
        assembly ("memory-safe") {
            if amount {
                let tokenIndex

                switch record
                case 0 { tokenIndex := UNRECORDED_TOKEN_MASK }
                case 1 {
                    tokenIndex := sload(TOKEN_FACET_STORAGE)
                    sstore(TOKEN_FACET_STORAGE, add(tokenIndex, 1))
                    sstore(add(tokenIndex, TOKEN_FACET_STORAGE_START), token)
                }

                sstore(token, add(shl(224, tokenIndex), amount))
            }
        }
    }

    /// @notice get token address an amount which involved in multicall
    function getAmountForToken(address token) internal returns (uint256 value) {
        assembly ("memory-safe") {
            value := sload(token)

            if value {
                sstore(token, 0)

                let tokenIndex := shr(224, value)
                if lt(tokenIndex, UNRECORDED_TOKEN_MASK) { sstore(add(TOKEN_FACET_STORAGE_START, tokenIndex), 0) }
                value := shr(32, shl(32, value))
            }
        }
    }
}
