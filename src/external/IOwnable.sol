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
    // getters
    // =========================

    /// @notice Returns the address of the current owner.
    /// @return The address of the current owner.
    function owner() external view returns (address);
}
