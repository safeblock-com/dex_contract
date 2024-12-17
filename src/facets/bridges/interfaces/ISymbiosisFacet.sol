// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ISymbiosisFacet - SymbiosisFacet interface
interface ISymbiosisFacet {
    // =========================
    // getters
    // =========================

    /// @notice Gets portal address
    function portal() external view returns (address);

    // =========================
    // main function
    // =========================

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

    /// @notice Send Symbiosis Transaction
    function sendSymbiosis(SymbiosisTransaction calldata symbiosisTransaction) external;
}
