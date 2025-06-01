// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ISymbiosisFacet - SymbiosisFacet interface
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
        uint256 stableBridgingFee;
        uint256 amount;
        address rtoken;
        address chain2address;
        address[] swapTokens;
        bytes secondSwapCalldata;
        address finalReceiveSide;
        bytes finalCalldata;
        uint256 finalOffset;
    }

    /// @notice Initiates a cross-chain bridging transaction via the Symbiosis protocol.
    /// @dev Transfers tokens from the sender (or uses pre-transferred tokens), applies protocol fees,
    ///      approves the Portal contract, and calls `metaSynthesize` to bridge tokens to the target chain.
    ///      Uses hardcoded addresses and chain ID for BOBA BNB.
    /// @param symbiosisTransaction The configuration for the cross-chain bridging transaction.
    function sendSymbiosis(SymbiosisTransaction calldata symbiosisTransaction) external;
}
