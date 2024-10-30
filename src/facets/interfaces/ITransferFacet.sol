// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ITransferFacet - interface for TransferFacet
interface ITransferFacet {
    /// @notice Transfer ERC20 token to `to`
    function transferToken(address token, uint256 amount, address to) external returns (uint256);

    /// @notice Transfer native token to `to`
    function transferNative(address to, uint256 amount) external returns (uint256);

    /// @notice Unwrap native token
    function unwrapNative(uint256 amount) external returns (uint256);

    /// @notice Unwrap native token and transfer to `to`
    function unwrapNativeAndTransferTo(address to, uint256 amount) external returns (uint256);
}
