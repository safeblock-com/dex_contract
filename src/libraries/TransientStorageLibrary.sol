// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { CALLBACK_FACET_STORAGE, SENDER_FACET_STORAGE } from "./Constants.sol";

/// @title TransientStorageLibrary
/// @notice Library for managing transient (temporary) storage in a diamond-like proxy contract.
/// @dev This library provides low-level assembly access to fixed storage slots
///      used to store addresses for callbacks and senders across internal calls.
///      All storage operations are done directly using `sload` and `sstore` to optimize gas.
///      This library is used throughout the protocol to handle temporary storage needs.
library TransientStorageLibrary {
    // =========================
    // Functions
    // =========================

    /// @notice Retrieve the current callback address and reset it to zero after reading.
    /// @dev Reads the address stored in the `CALLBACK_FACET_STORAGE` slot using inline assembly.
    ///      If a non-zero address is found, it is returned and the slot is cleared (set to zero).
    /// @return callbackAddress The address that was set as callback, or zero if unset.
    function getCallbackAddress() internal returns (address callbackAddress) {
        assembly ("memory-safe") {
            callbackAddress := sload(CALLBACK_FACET_STORAGE)
            if callbackAddress { sstore(CALLBACK_FACET_STORAGE, 0) }
        }
    }

    /// @notice Temporarily store a callback address in a fixed storage slot.
    /// @dev Stores the given address into `CALLBACK_FACET_STORAGE`. Can later be retrieved via `getCallbackAddress()`.
    /// @param callbackAddress The address to store as callback for use by downstream logic.
    function setCallbackAddress(address callbackAddress) internal {
        assembly ("memory-safe") {
            sstore(CALLBACK_FACET_STORAGE, callbackAddress)
        }
    }

    /// @notice Retrieve the current stored sender address.
    /// @dev Reads the address stored in the `SENDER_FACET_STORAGE` slot.
    ///      It is assumed that this value has been set prior by `setSenderAddress`.
    ///      May return zero if never initialized.
    /// @return senderAddress The sender address stored in transient storage.
    function getSenderAddress() internal view returns (address senderAddress) {
        assembly ("memory-safe") {
            senderAddress := sload(SENDER_FACET_STORAGE)
        }
    }

    /// @notice Store a sender address in a fixed storage slot.
    /// @dev Writes the provided address into the `SENDER_FACET_STORAGE` slot.
    ///      Reverts if the slot is already occupied (i.e., potential reentrancy).
    ///      This function should be called at the start of a trusted flow and cleared afterward.
    /// @param senderAddress The address to store as sender context.
    function setSenderAddress(address senderAddress) internal {
        assembly ("memory-safe") {
            if sload(SENDER_FACET_STORAGE) { revert(0, 0) } // TODO: replace with proper reentrancy error
            sstore(SENDER_FACET_STORAGE, senderAddress)
        }
    }

    /// @notice Clears the sender address from transient storage.
    /// @dev Resets the `SENDER_FACET_STORAGE` slot to zero. Should be called after the operation is done.
    function cleanSenderAddress() internal {
        assembly ("memory-safe") {
            sstore(SENDER_FACET_STORAGE, 0)
        }
    }
}
