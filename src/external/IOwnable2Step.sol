// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOwnable } from "./IOwnable.sol";

/// @title IOwnable2Step - Ownable2Step Interface
/// @notice Interface for two-step ownership transfer functionality
/// @dev Extends IOwnable to provide a safer ownership transfer mechanism
interface IOwnable2Step is IOwnable {
    // =========================
    // events
    // =========================

    /// @notice Emits when the account ownership transfer to `newOwner` procedure begins.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    // =========================
    // getters
    // =========================

    /// @notice Returns the address of the pending owner.
    /// @return The address of the pending owner.
    function pendingOwner() external view returns (address);

    // =========================
    // main functions
    // =========================

    /// @notice Starts the ownership transfer of the contract to a new account.
    /// @dev Replaces the pending transfer if there is one.
    /// Can only be called by the current owner.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external;

    /// @notice The new owner accepts the ownership transfer.
    /// @dev Can only be called by the pending owner.
    function acceptOwnership() external;

    /// @notice Leaves the contract without an owner. It will not be possible to call
    /// `onlyOwner` functions anymore.
    /// @dev Can only be called by the current owner.
    function renounceOwnership() external;
}
