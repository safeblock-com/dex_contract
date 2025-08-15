// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IOwnable - Ownable Interface
/// @notice Interface for ownership management in contracts
/// @dev This interface defines the standard functions for ownership control
interface IOwnable {
    // =========================
    // events
    // =========================

    /// @notice Emits when ownership of the contract is transferred from `previousOwner`
    /// to `newOwner`.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // =========================
    // errors
    // =========================

    /// @dev Thrown when the caller is not the current contract owner.
    /// @param sender The address attempting the restricted action.
    error Ownable_SenderIsNotOwner(address sender);

    /// @dev Thrown when the caller is not the pending new owner in a two-step ownership transfer.
    /// @param caller The address attempting to accept ownership.
    error Ownable_CallerIsNotTheNewOwner(address caller);

    /// @dev Thrown when trying to set the new owner to the zero address.
    error Ownable_NewOwnerCannotBeAddressZero();

    // =========================
    // getters
    // =========================

    /// @notice Returns the address of the current owner.
    /// @return The address of the current owner.
    function owner() external view returns (address);
}
