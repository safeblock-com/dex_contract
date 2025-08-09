// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ICoinFlippersVault
/// @notice Interface for the CoinFlippers vault functionality
/// @dev This interface provides functions for interacting with the CoinFlippers vault
interface ICoinFlippersVault {
    /// @notice Deposits a flexible amount of tokens into the vault
    /// @dev This function allows depositing a flexible amount of tokens into the vault using a signed permit
    /// @param merchantId The merchant identifier
    /// @param paymentId The payment identifier
    /// @param tokenAddress The address of the token to deposit
    /// @param amount The amount of tokens to deposit
    /// @param deadline The deadline for the permit signature
    /// @param signature The signature for the permit
    function depositFlexibleAmount(
        bytes32 merchantId,
        bytes32 paymentId,
        address tokenAddress,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    )
        external;
}
