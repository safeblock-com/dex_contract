// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICrossCurveRouter } from "./ICrossCurveRouter.sol";

/// @title ICrossCurveFacet - CrossCurveFacet interface
/// @notice Interface for the CrossCurveFacet contract for cross-chain token bridging
/// @dev This interface defines the functions and structures for interacting with the CrossCurve protocol
interface ICrossCurveFacet {
    // =========================
    // send function
    // =========================

    /// @notice Starts a cross-chain operation via the CrossCurve protocol.
    /// @dev This function prepares tokens for the cross-chain operation, approves the router, and initiates the operation.
    /// @param operations The array of operation names to execute.
    /// @param params The array of parameters for each operation.
    /// @param receipt The invoice details for the cross-chain operation including:
    ///        - chainId: The destination chain ID
    ///        - token: The token to send
    ///        - amount: The amount to send
    ///        - receiver: The recipient address
    ///        - executionPrice: The execution price for the operation
    /// @return tokensAndAmounts The updated array of token addresses and amounts after the operation.
    function startCrossCurve(
        string[] calldata operations,
        bytes[] calldata params,
        ICrossCurveRouter.Invoice calldata receipt
    )
        external
        returns (bytes32[] memory tokensAndAmounts);
}
