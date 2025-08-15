// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ICrossCurveRouter
/// @notice Interface for the CrossCurve router contract.
/// @dev This interface defines the functions and structures for interacting with the CrossCurve protocol.
interface ICrossCurveRouter {
    /// @notice Structure representing an invoice for a cross-chain operation.
    /// @dev Contains the parameters needed to validate and execute a cross-chain operation.
    struct Invoice {
        /// @notice The price to pay for execution.
        uint256 executionPrice;
        /// @notice The deadline for the operation.
        uint256 deadline;
        /// @notice The v component of the signature.
        uint8 v;
        /// @notice The r component of the signature.
        bytes32 r;
        /// @notice The s component of the signature.
        bytes32 s;
    }

    /// @notice Starts a cross-chain operation.
    /// @dev This function initiates a cross-chain operation with the provided parameters and invoice.
    /// @param operations The array of operation names to execute.
    /// @param params The array of parameters for each operation.
    /// @param receipt The invoice details for the cross-chain operation.
    function start(string[] calldata operations, bytes[] calldata params, Invoice calldata receipt) external payable;

    /// @notice Resumes a cross-chain operation.
    /// @dev This function resumes a previously started cross-chain operation.
    /// @param requestId The ID of the request to resume.
    /// @param cPos The position in the call stack.
    /// @param operations The array of operation names to execute.
    /// @param params The array of parameters for each operation.
    function resume(bytes32 requestId, uint8 cPos, string[] calldata operations, bytes[] calldata params) external;
}
