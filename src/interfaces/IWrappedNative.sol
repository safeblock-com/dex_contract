// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IWrappedNative
/// @notice Interface for Wrapped Native tokens (e.g., WETH)
/// @dev This interface defines the standard functions for wrapped native tokens
interface IWrappedNative {
    /// @notice Deposit native currency (e.g., ETH) and receive wrapped tokens (e.g., WETH)
    /// @dev Transfers the native currency sent with this call to the contract and mints wrapped tokens
    function deposit() external payable;

    /// @notice Withdraw native currency by burning wrapped tokens
    /// @dev Burns the specified amount of wrapped tokens and transfers the equivalent native currency to the caller
    /// @param wad The amount of wrapped tokens to burn and native currency to receive
    function withdraw(uint256 wad) external;
}
