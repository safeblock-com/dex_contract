// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ITransferFacet - interface for TransferFacet
interface ITransferFacet {
    // =========================
    // errors
    // =========================

    /// @dev Throws when transfer from via permit2 fails
    error TransferFacet_TransferFromFailed();

    // =========================
    // getters
    // =========================

    /// @notice Returns nonce for permit2 signature
    function getNonceForPermit2(address user) external view returns (uint256);

    // =========================
    // functions
    // =========================

    /// @notice Transfer ERC20 token using a signed permit by permit2 contract
    function transferFromPermit2(
        address token,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    )
        external;

    /// @notice Transfer ERC20 `tokens` to `to`
    function transferToken(address to, address[] calldata tokens) external;

    /// @notice Unwrap native token and transfer to `to`
    function unwrapNativeAndTransferTo(address to) external;
}
