// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { TransferHelper } from "./libraries/TransferHelper.sol";
import { IWrappedNative } from "./interfaces/IWrappedNative.sol";

/// @title TransferFacet - Facet for token transfers
contract TransferFacet {
    // =========================
    // storage
    // =========================

    /// @dev address of the WrappedNative contract for current chain
    IWrappedNative private immutable _wrappedNative;

    // =========================
    // constructor
    // =========================

    /// @notice Constructor
    constructor(address wrappedNative) {
        _wrappedNative = IWrappedNative(wrappedNative);
    }

    // =========================
    // functions
    // =========================

    /// @notice Transfer ERC20 token to `to`
    function transferToken(address token, uint256 amount, address to) external returns (uint256) {
        TransferHelper.safeTransfer({ token: token, to: to, value: amount });

        return amount;
    }

    /// @notice Transfer native token to `to`
    function transferNative(address to, uint256 amount) external returns (uint256) {
        TransferHelper.safeTransferNative({ to: to, value: amount });

        return amount;
    }

    /// @notice Unwrap native token and transfer to `to`
    function unwrapNativeAndTransferTo(address to, uint256 amount) external returns (uint256) {
        _wrappedNative.withdraw({ wad: amount });

        TransferHelper.safeTransferNative({ to: to, value: amount });

        return amount;
    }
}
