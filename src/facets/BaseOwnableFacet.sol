// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IErrors } from "../interfaces/IErrors.sol";

import { TransientStorageLibrary } from "../libraries/TransientStorageLibrary.sol";

/// @title BaseOwnableFacet
/// @notice A base contract providing ownership-based access control for facets in a diamond-like proxy
/// @dev Implements a single-owner model with a modifier to restrict function access.
///      Uses `TransientStorageLibrary` to verify the original sender in delegated calls.
///      This contract is intended to be inherited by facets that require owner-only access control.
abstract contract BaseOwnableFacet {
    // =========================
    // storage
    // =========================

    /// @dev The address of the contract owner.
    ///      Stored privately to prevent direct access. Set via `EntryPoint`'s ownership transfer mechanisms.
    address private _owner;

    // =========================
    // modifiers
    // =========================

    /// @notice Restricts function access to the contract owner
    /// @dev Reverts with `IErrors.Ownable_SenderIsNotOwner` if the caller or original sender is not the owner.
    ///      This modifier should be used on functions that should only be callable by the contract owner.
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    // =========================
    // internal functions
    // =========================

    /// @dev Verifies if the caller or original sender is the contract owner
    /// @dev Checks `msg.sender` and the sender stored in `TransientStorageLibrary` against `_owner`.
    ///      Reverts with `IErrors.Ownable_SenderIsNotOwner` if neither matches.
    ///      This function is used by the `onlyOwner` modifier to enforce access control.
    function _checkOwner() internal view {
        address owner = _owner;
        if (owner != msg.sender) {
            address sender = TransientStorageLibrary.getSenderAddress();
            if (owner != sender) {
                revert IErrors.Ownable_SenderIsNotOwner({ sender: sender });
            }
        }
    }
}
