// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ISymbiosisFacet - SymbiosisFacet interface
/// @notice Interface for the Symbiosis facet functionality
/// @dev This interface provides functions for interacting with the Symbiosis protocol for cross-chain token bridging
interface ISymbiosisFacet {
    // =========================
    // getters
    // =========================

    /// @notice Retrieves the address of the Symbiosis Portal contract.
    /// @dev Returns the immutable `_portal` address.
    /// @return The address of the Symbiosis Portal contract.
    function portal() external view returns (address);

    // =========================
    // main function
    // =========================

    /// @notice Configuration for a cross-chain bridging transaction via the Symbiosis protocol.
    /// @dev Specifies the token, amount, and parameters for bridging to a target chain, including optional swap and final call details.
    struct SymbiosisTransaction {
        /// @notice Stable bridging fee amount
        uint256 stableBridgingFee;
        /// @notice Address of the token to bridge
        address rtoken;
        /// @notice Recipient address on the destination chain
        address chain2address;
        /// @notice Array of swap tokens
        address[] swapTokens;
        /// @notice Calldata for the second swap
        bytes secondSwapCalldata;
        /// @notice Final receive side contract address
        address finalReceiveSide;
        /// @notice Final calldata for the transaction
        bytes finalCalldata;
        /// @notice Final offset for the calldata
        uint256 finalOffset;
    }

    /// @notice Initiates a cross-chain bridging transaction via the Symbiosis protocol.
    /// @dev Transfers tokens from the sender (or uses pre-transferred tokens), applies protocol fees,
    ///      approves the Portal contract, and calls `metaSynthesize` to bridge tokens to the target chain.
    ///      Uses hardcoded addresses and chain ID for BOBA BNB.
    /// @param symbiosisTransaction The configuration for the cross-chain bridging transaction.
    /// @return tokensAndAmounts Array of token and amount pairs
    function sendSymbiosis(SymbiosisTransaction calldata symbiosisTransaction)
        external
        returns (bytes32[] memory tokensAndAmounts);
}
