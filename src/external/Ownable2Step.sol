// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IOwnable2Step } from "./IOwnable2Step.sol";
import { Ownable } from "./Ownable.sol";

/// @title Ownable2Step
/// @dev Contract module which provides access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// By default, the owner account will be the one that sets during deployment. This
/// can later be changed with {transferOwnership} and {acceptOwnership}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
abstract contract Ownable2Step is Ownable, IOwnable2Step {
    // =========================
    // storage
    // =========================

    /// @dev Private variable to store the pendingOwner's address.
    address private _pendingOwner;

    // =========================
    // getters
    // =========================

    /// @inheritdoc IOwnable2Step
    function pendingOwner() external view returns (address) {
        return _pendingOwner;
    }

    // =========================
    // main functions
    // =========================

    /// @inheritdoc IOwnable2Step
    function transferOwnership(address newOwner) external onlyOwner {
        _checkIsNotAddressZero(newOwner);

        _pendingOwner = newOwner;
        emit IOwnable2Step.OwnershipTransferStarted(_owner, newOwner);
    }

    /// @inheritdoc IOwnable2Step
    function acceptOwnership() external {
        if (msg.sender != _pendingOwner) {
            revert Ownable_CallerIsNotTheNewOwner(msg.sender);
        }

        _transferOwnership(msg.sender);
    }

    /// @inheritdoc IOwnable2Step
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    // =========================
    // internal functions
    // =========================

    /// @dev Internal function to verify if the account is not the address zero.
    function _checkIsNotAddressZero(address account) internal pure {
        if (account == address(0)) {
            revert Ownable_NewOwnerCannotBeAddressZero();
        }
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
    /// Internal function without access restriction.
    /// Emits an {OwnershipTransferred} event.
    function _transferOwnership(address newOwner) internal override {
        delete _pendingOwner;

        super._transferOwnership(newOwner);
    }
}
