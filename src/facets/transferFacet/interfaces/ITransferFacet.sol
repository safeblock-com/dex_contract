// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ITransferFacet - interface for TransferFacet
/// @notice Interface for the Transfer facet functionality
/// @dev This interface provides functions for handling token transfers in a diamond-like proxy contract
interface ITransferFacet {
    // =========================
    // getters
    // =========================

    /// @notice Retrieves the next available nonce for a user's Permit2 signature.
    /// @dev Queries the Permit2 contract's `nonceBitmap` function to find the first unused nonce for the user,
    ///      then iterating over nonce words.
    /// @param user The address of the user whose nonce is being queried.
    /// @return nonce The next available nonce for the user's Permit2 signature.
    function getNonceForPermit2(address user) external view returns (uint256);

    // =========================
    // functions
    // =========================

    /// @notice Transfers multiple ERC20 tokens to a specified address.
    /// @dev Iterates over the provided token array, retrieves amounts from `TransientStorageLibrary`,
    ///      and transfers non-zero amounts using `TransferHelper`.
    /// @param to The recipient address for the token transfers.
    /// @param tokens The array of ERC20 token addresses to transfer.
    /// @return tokensAndAmounts Array of token and amount pairs
    function transferToken(
        address to,
        address[] calldata tokens
    )
        external
        returns (bytes32[] memory tokensAndAmounts);

    /// @notice Unwraps Wrapped Native tokens to native currency and transfers to a specified address.
    /// @dev Retrieves the Wrapped Native token amount from `TransientStorageLibrary`,
    ///      calls `withdraw` on the Wrapped Native contract, and transfers the native currency using `TransferHelper`.
    /// @param to The recipient address for the native currency transfer.
    /// @return tokensAndAmounts Array of token and amount pairs
    function unwrapNativeAndTransferTo(address to) external returns (bytes32[] memory tokensAndAmounts);
}
