// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IOwnable } from "../external/IOwnable.sol";

/// @title BaseOwnableFacet
/// @dev Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
abstract contract BaseOwnableFacet {
    // =========================
    // storage
    // =========================

    /// @dev Private variable to store the owner's address.
    address private _owner;

    // =========================
    // modifiers
    // =========================

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    // =========================
    // internal functions
    // =========================

    /// @dev Internal function to verify if the caller is the owner of the contract.
    /// Errors:
    /// - Thrown `Ownable_SenderIsNotOwner` if the caller is not the owner.
    function _checkOwner() internal view {
        if (_owner != msg.sender) {
            revert IOwnable.Ownable_SenderIsNotOwner(msg.sender);
        }
    }
}
