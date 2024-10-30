// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { TransferHelper } from "./libraries/TransferHelper.sol";
import { IWrappedNative } from "./interfaces/IWrappedNative.sol";

import { ITransferFacet } from "./interfaces/ITransferFacet.sol";

/// @title TransferFacet - Facet for token transfers
contract TransferFacet is ITransferFacet {
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

    /// @inheritdoc ITransferFacet
    function transferToken(address token, uint256 amount, address to) external returns (uint256) {
        if (amount > 0) {
            TransferHelper.safeTransfer({ token: token, to: to, value: amount });
        }

        return amount;
    }

    /// @inheritdoc ITransferFacet
    function transferNative(address to, uint256 amount) external returns (uint256) {
        if (amount > 0) {
            TransferHelper.safeTransferNative({ to: to, value: amount });
        }

        return amount;
    }

    /// @inheritdoc ITransferFacet
    function unwrapNative(uint256 amount) external returns (uint256) {
        if (amount > 0) {
            _wrappedNative.withdraw({ wad: amount });
        }

        return amount;
    }

    /// @inheritdoc ITransferFacet
    function unwrapNativeAndTransferTo(address to, uint256 amount) external returns (uint256) {
        if (amount > 0) {
            _wrappedNative.withdraw({ wad: amount });

            TransferHelper.safeTransferNative({ to: to, value: amount });
        }

        return amount;
    }
}
