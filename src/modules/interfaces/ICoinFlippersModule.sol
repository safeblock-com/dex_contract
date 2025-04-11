// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ICoinFlippersModule - CoinFlippersModule interface
interface ICoinFlippersModule {
    /// @notice Deposits tokens into the CoinFlippersVault
    function deposit(
        bytes32 merchantId,
        bytes32 paymentId,
        address tokenAddress,
        uint256 deadline,
        bytes memory signature
    )
        external;
}
