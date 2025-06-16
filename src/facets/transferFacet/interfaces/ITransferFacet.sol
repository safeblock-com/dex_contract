// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ITransferFacet - interface for TransferFacet
interface ITransferFacet {
    // =========================
    // errors
    // =========================

    /// @dev Thrown when a transfer via Permit2 fails to increase the contract's token balance.
    error TransferFacet_TransferFromFailed();

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

    /// @notice Transfers ERC20 tokens to this contract using a signed Permit2 permit.
    /// @dev Calls `permitTransferFrom` on the Permit2 contract, verifies the transfer by checking the balance increase,
    ///      and records the transferred amount in `TransientStorageFacetLibrary`.
    ///      Reverts with `TransferFacet_TransferFromFailed` if the balance does not increase.
    /// @param token The address of the ERC20 token to transfer.
    /// @param amount The amount of tokens to transfer.
    /// @param nonce The nonce for the Permit2 signature.
    /// @param deadline The deadline for the Permit2 signature.
    /// @param signature The signature for the Permit2 permit.
    function transferFromPermit2(
        address token,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    )
        external;

    /// @notice Transfers multiple ERC20 tokens to a specified address.
    /// @dev Iterates over the provided token array, retrieves amounts from `TransientStorageFacetLibrary`,
    ///      and transfers non-zero amounts using `TransferHelper`.
    /// @param to The recipient address for the token transfers.
    /// @param tokens The array of ERC20 token addresses to transfer.
    function transferToken(address to, address[] calldata tokens) external;

    /// @notice Unwraps Wrapped Native tokens to native currency and transfers to a specified address.
    /// @dev Retrieves the Wrapped Native token amount from `TransientStorageFacetLibrary`,
    ///      calls `withdraw` on the Wrapped Native contract, and transfers the native currency using `TransferHelper`.
    /// @param to The recipient address for the native currency transfer.
    function unwrapNativeAndTransferTo(address to) external;
}
