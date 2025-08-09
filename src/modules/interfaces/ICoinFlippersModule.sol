// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ICoinFlippersModule
/// @notice Interface for the CoinFlippers module functionality
/// @dev This interface provides functions for interacting with the CoinFlippers module
interface ICoinFlippersModule {
    /// @notice Deposits tokens into the CoinFlippersVault
    /// @dev This function allows depositing tokens into the CoinFlippersVault using a signed permit
    /// @param merchantId The merchant identifier
    /// @param paymentId The payment identifier
    /// @param tokenAddress The address of the token to deposit
    /// @param deadline The deadline for the permit signature
    /// @param signature The signature for the permit
    /// @return tokensAndAmounts Array of token and amount pairs
    function deposit(
        bytes32 merchantId,
        bytes32 paymentId,
        address tokenAddress,
        uint256 deadline,
        bytes memory signature
    )
        external
        returns (bytes32[] memory tokensAndAmounts);
}
