// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IOwnable } from "../external/IOwnable.sol";

import { TransientStorageFacetLibrary } from "../libraries/TransientStorageFacetLibrary.sol";

/// @title BaseOwnableFacet
/// @notice A base contract providing ownership-based access control for facets in a diamond-like proxy.
/// @dev Implements a single-owner model with a modifier to restrict function access.
///      Uses `TransientStorageFacetLibrary` to verify the original sender in delegated calls.
abstract contract BaseOwnableFacet {
    // =========================
    // storage
    // =========================

    /// @dev The address of the contract owner.
    ///      Stored privately to prevent direct access. Set via `EntryPoint`’s ownership transfer mechanisms.
    address private _owner;

    // =========================
    // modifiers
    // =========================

    /// @dev Restricts function access to the contract owner.
    ///      Reverts with `IOwnable.Ownable_SenderIsNotOwner` if the caller or original sender is not the owner.
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    // =========================
    // internal functions
    // =========================

    /// @dev Verifies if the caller or original sender is the contract owner.
    ///      Checks `msg.sender` and the sender stored in `TransientStorageFacetLibrary` against `_owner`.
    ///      Reverts with `IOwnable.Ownable_SenderIsNotOwner` if neither matches.
    function _checkOwner() internal view {
        address owner = _owner;
        if (owner != msg.sender) {
            address sender = TransientStorageFacetLibrary.getSenderAddress();
            if (owner != sender) {
                revert IOwnable.Ownable_SenderIsNotOwner({ sender: sender });
            }
        }
    }
}
