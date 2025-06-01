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
/// @notice Library for managing transient storage in a diamond-like proxy contract.
/// @dev Uses assembly for efficient storage operations to manage callback addresses, sender addresses, fees, and token amounts.
library TransientStorageFacetLibrary {
    // =========================
    // errors
    // =========================

    /// @dev Thrown when a token is not transferred from the contract after a call.
    error TokenNotTransferredFromContract();

    /// @dev Thrown when the sender address is zero during retrieval.
    error TransientStorageFacetLibrary_InvalidSenderAddress();

    // =========================
    // functions
    // =========================

    /// @dev Retrieves the callback address and resets it to zero if set.
    ///      Reads from the `CALLBACK_FACET_STORAGE` slot and clears it if non-zero.
    /// @return callbackAddress The current callback address.
    function getCallbackAddress() internal returns (address callbackAddress) {
        assembly ("memory-safe") {
            callbackAddress := sload(CALLBACK_FACET_STORAGE)
            if callbackAddress { sstore(CALLBACK_FACET_STORAGE, 0) }
        }
    }

    /// @dev Sets the callback address to storage temporarily.
    ///      Stores the provided address in the `CALLBACK_FACET_STORAGE` slot.
    /// @param callbackAddress The address to set as the callback.
    function setCallbackAddress(address callbackAddress) internal {
        assembly ("memory-safe") {
            sstore(CALLBACK_FACET_STORAGE, callbackAddress)
        }
    }

    /// @dev Retrieves the sender address from temporary storage.
    ///      Reads from the `SENDER_FACET_STORAGE` slot.
    ///      Reverts with `TransientStorageFacetLibrary_InvalidSenderAddress` if the sender is zero.
    /// @return senderAddress The current sender address.
    function getSenderAddress() internal view returns (address senderAddress) {
        assembly ("memory-safe") {
            senderAddress := sload(SENDER_FACET_STORAGE)
        }
        if (senderAddress == address(0)) {
            revert TransientStorageFacetLibrary_InvalidSenderAddress();
        }
    }

    /// @dev Checks if a fee has been paid and sets the fee paid flag if not.
    ///      Reads the `SENDER_FACET_STORAGE` slot to check the fee flag.
    ///      Sets the `FEE_PAID_FLAG` if the fee is unpaid and the value is non-zero.
    /// @return _isFeePaid True if the fee is paid or the storage value is zero, false otherwise.
    function isFeePaid() internal returns (bool _isFeePaid) {
        assembly ("memory-safe") {
            let value := sload(SENDER_FACET_STORAGE)
            _isFeePaid := or(shr(160, value), eq(value, address()))
            if and(gt(value, 0), iszero(_isFeePaid)) { sstore(SENDER_FACET_STORAGE, add(value, FEE_PAID_FLAG)) }
        }
    }

    /// @dev Sets the sender address in temporary storage and clears token data if the sender is zero.
    ///      Stores the sender in the `SENDER_FACET_STORAGE` slot. If the sender is zero,
    ///      clears token data and reverts with `TokenNotTransferredFromContract` if any tokens remain.
    /// @param senderAddress The address to set as the sender.
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
                        mstore(0, 0xc26d3d6a) // TokenNotTransferredFromContract
                        revert(28, 4)
                    }
                }
            }
        }
    }

    /// @dev Sets the amount for a token involved in a multicall, optionally recording the token.
    ///      Stores the amount and token index in the token's storage slot. If `record` is true,
    ///      stores the token address in the `TOKEN_FACET_STORAGE` array.
    /// @param token The address of the token.
    /// @param amount The amount of the token.
    /// @param record Whether to record the token in the storage array.
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

    /// @dev Retrieves and clears the amount for a token involved in a multicall.
    ///      Reads the amount and token index from the token's storage slot, clears the slot,
    ///      and clears the token from the storage array if recorded.
    /// @param token The address of the token.
    /// @return value The amount of the token.
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
