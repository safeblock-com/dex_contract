// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IEntryPoint - EntryPoint interface
interface IEntryPoint {
    // =========================
    // errors
    // =========================

    /// @notice Throws when the function does not exist in the EntryPoint.
    error EntryPoint_FunctionDoesNotExist(bytes4 selector);

    /// @notice Executes multiple calls in a single transaction.
    /// @dev Iterates through an array of call data and executes each call.
    /// If any call fails, the function reverts with the original error message.
    /// @param data An array of call data to be executed.
    function multicall(bytes[] calldata data) external payable;
}
