// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IWrappedNative } from "../interfaces/IWrappedNative.sol";
import { TransferHelper } from "../libraries/TransferHelper.sol";

import { IConnext } from "./connext/IConnext.sol";

import { BaseOwnableFacet } from "../BaseOwnableFacet.sol";

contract ConnextFacet is BaseOwnableFacet {
    using TransferHelper for address;

    address private immutable _wrappedNative;

    IConnext private immutable _connext;

    constructor(address wrappedNative, address connext) {
        _wrappedNative = wrappedNative;
        _connext = IConnext(connext);
    }

    // =========================
    // connext
    // =========================

    /// @notice Transfers assets from one chain to another.
    /// @dev User should approve a spending allowance before calling this.
    /// @param token Address of the token on this domain.
    /// @param amount The amount to transfer.
    /// @param recipient The destination address (e.g. a wallet).
    /// @param destinationDomain The destination domain ID.
    /// @param slippage The maximum amount of slippage the user will accept in BPS.
    /// @param relayerFee The fee offered to relayers.
    function xTransfer(
        address token,
        uint256 amount,
        address recipient,
        uint32 destinationDomain,
        uint256 slippage,
        uint256 relayerFee
    )
        external
        payable
    {
        bytes memory callData;

        if (token == _wrappedNative) {
            // Wrap ETH into WETH to send with the xcall
            IWrappedNative(_wrappedNative).deposit{ value: amount }();
            callData = abi.encode(recipient);
        } else {
            token.safeTransferFrom({ from: msg.sender, to: address(this), value: amount });
        }

        // This contract approves transfer to Connext
        token.safeApprove({ spender: address(_connext), value: amount });

        _connext.xcall{ value: relayerFee }({
            destination: destinationDomain, // Domain ID of the destination chain
            to: recipient, // address receiving the funds on the destination
            asset: token, // address of the token contract
            delegate: msg.sender, // address that can revert or forceLocal on destination
            amount: amount, // amount of tokens to transfer
            slippage: slippage, // the maximum amount of slippage the user will accept in BPS (e.g. 30 = 0.3%)
            callData: callData
        });
    }
}
