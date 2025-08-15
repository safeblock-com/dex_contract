// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Utils } from "../../libraries/Utils.sol";
import { OptionsBuilder } from "../../libraries/external/OptionsBuilder.sol";
import { OFTComposeMsgCodec } from "../../libraries/external/OFTComposeMsgCodec.sol";
import { TransferHelper } from "../../libraries/TransferHelper.sol";
import { TransientStorageLibrary } from "../../libraries/TransientStorageLibrary.sol";

import { IStargate, SendParam, MessagingFee } from "./interfaces/IStargate.sol";
import { OFTReceipt } from "./interfaces/IOFT.sol";
import { ILayerZeroComposer } from "./interfaces/ILayerZeroComposer.sol";

import { IStargateFacet } from "./interfaces/IStargateFacet.sol";

/// @title StargateFacet
/// @notice A facet for cross-chain token bridging and messaging via the Stargate and LayerZero protocols
///         in a diamond-like proxy contract.
/// @dev Supports sending tokens across chains, quoting fees, and handling LayerZero compose messages
///      with callbacks.
///      This facet is part of the diamond proxy pattern and provides functionality for cross-chain token bridging
///      using the Stargate and LayerZero protocols. It integrates with the EntryPoint contract to route calls appropriately.
contract StargateFacet is ILayerZeroComposer, IStargateFacet {
    using OptionsBuilder for bytes;

    // =========================
    // storage
    // =========================

    /// @dev The address of the LayerZero V2 endpoint contract.
    ///      Immutable, set during construction. Used for validating incoming compose messages in `lzCompose`.
    address private immutable _lzEndpointV2;

    // =========================
    // constructor
    // =========================

    /// @notice Initializes the StargateFacet with the LayerZero V2 endpoint address.
    /// @dev Sets the immutable `_lzEndpointV2` address.
    /// @param endpointV2 The address of the LayerZero V2 endpoint contract.
    constructor(address endpointV2) {
        _lzEndpointV2 = endpointV2;
    }
    // =========================
    // getters
    // =========================

    /// @inheritdoc IStargateFacet
    function lzEndpoint() external view returns (address) {
        return _lzEndpointV2;
    }

    // =========================
    // quoter
    // =========================

    /// @inheritdoc IStargateFacet
    function quoteV2(
        address poolAddress,
        uint32 dstEid,
        uint256 amountLD,
        address receiver,
        bytes memory composeMsg,
        uint128 composeGasLimit
    )
        external
        view
        returns (uint256 valueToSend, uint256 dstAmount)
    {
        SendParam memory sendParam;
        (valueToSend, sendParam,) = _quoteV2(
            poolAddress, IStargate(poolAddress).token(), dstEid, amountLD, receiver, composeMsg, composeGasLimit
        );

        dstAmount = sendParam.minAmountLD;
    }

    // =========================
    // send
    // =========================

    /// @inheritdoc IStargateFacet
    function sendStargateV2(
        address poolAddress,
        uint32 dstEid,
        address receiver,
        uint128 composeGasLimit,
        bytes memory composeMsg
    )
        external
        returns (bytes32[] memory tokensAndAmounts)
    {
        address token = IStargate(poolAddress).token();
        uint256 amountLD;

        tokensAndAmounts = Utils.decodeTokensAndAmountsArray();
        if (token > address(0)) {
            amountLD = Utils.getAmountFromArrayAndDelete({ tokensAndAmounts: tokensAndAmounts, token: token });
            Utils.expectNotZero({ value: amountLD });
        } else {
            revert IStargateFacet.StargateFacet_UnsupportedAsset();
        }

        uint256 balanceBefore = TransferHelper.safeGetBalance({ token: token, account: address(this) });

        (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) =
            _quoteV2(poolAddress, token, dstEid, amountLD, receiver, composeMsg, composeGasLimit);

        Utils.compareAmounts({ greaterValue: address(this).balance, lowerValue: valueToSend });

        TransferHelper.safeApprove({ token: token, spender: poolAddress, value: amountLD });

        IStargate(poolAddress).sendToken{ value: valueToSend }({
            sendParam: sendParam,
            fee: messagingFee,
            refundAddress: TransientStorageLibrary.getSenderAddress()
        });

        unchecked {
            uint256 balanceAfter =
                amountLD - (balanceBefore - TransferHelper.safeGetBalance({ token: token, account: address(this) }));

            if (balanceAfter > 0) {
                Utils.addElementToArrayOrAddAmount({
                    tokensAndAmounts: tokensAndAmounts,
                    element: Utils.encodeTokenAndAmount({ token: token, amount: balanceAfter })
                });
            }
        }
    }

    // =========================
    // receive
    // =========================

    /// @inheritdoc ILayerZeroComposer
    function lzCompose(
        address, /* from */
        bytes32, /* guid */
        bytes calldata message,
        address, /* executor */
        bytes calldata /* extraData */
    )
        external
        payable
    {
        if (msg.sender != _lzEndpointV2) {
            revert IStargateFacet.StargateFacet_NotLZEndpoint();
        }

        uint256 amountLD = OFTComposeMsgCodec.amountLD({ _msg: message });
        bytes memory composeMessage = OFTComposeMsgCodec.composeMsg({ _msg: message });

        (address asset, address fallbackAddress, bytes memory payload) =
            abi.decode(composeMessage, (address, address, bytes));

        _sendCallback(asset, amountLD, fallbackAddress, payload);
    }

    // =========================
    // internal
    // =========================

    /// @dev Executes a cross-chain callback or transfers tokens to a fallback address on failure.
    /// @dev Records the token amount in transient storage, attempts a low-level call with the payload,
    ///      and handles failures by emitting `CallFailed` and transferring tokens to `fallbackAddress`.
    /// @param asset The address of the token received (or address(0) for native currency).
    /// @param amountLD The amount of tokens received (in local decimals).
    /// @param fallbackAddress The address to receive tokens if the callback fails.
    /// @param payload The encoded callback data to execute.
    function _sendCallback(address asset, uint256 amountLD, address fallbackAddress, bytes memory payload) internal {
        if (asset > address(0)) {
            bool successfulCall;
            assembly ("memory-safe") {
                let length := mload(payload)
                let offset := add(payload, add(32, length))
                mstore(offset, add(shl(160, amountLD), asset))
                mstore(add(offset, 32), 1)
                length := add(length, 64)

                successfulCall := call(gas(), address(), 0, add(payload, 32), length, 0, 0)

                if iszero(successfulCall) {
                    returndatacopy(add(payload, 32), 0, returndatasize())
                    mstore(payload, returndatasize())
                }
            }

            if (!successfulCall) {
                emit IStargateFacet.CallFailed({ errorMessage: payload });

                TransferHelper.safeTransfer({ token: asset, to: fallbackAddress, value: amountLD });
            }
        } else {
            TransferHelper.safeTransferNative({ to: fallbackAddress, value: amountLD });
        }
    }

    /// @dev Quotes the fee and parameters for a cross-chain token transfer.
    /// @dev Constructs a `SendParam` with optional compose message options, queries the Stargate pool for the minimum output (`quoteOFT`),
    ///      and calculates the native fee (`quoteSend`).
    /// @param poolAddress The address of the Stargate pool contract.
    /// @param token The address of the token to send.
    /// @param dstEid The destination chain’s LayerZero endpoint ID.
    /// @param amountLD The amount of tokens to send (in local decimals).
    /// @param receiver The recipient address on the destination chain.
    /// @param composeMsg The optional compose message for cross-chain execution.
    /// @param composeGasLimit The gas limit for the compose message execution.
    /// @return valueToSend The native currency fee required for the transfer.
    /// @return sendParam The `SendParam` struct with transfer details.
    /// @return messagingFee The `MessagingFee` struct with native and LZ token fees.
    function _quoteV2(
        address poolAddress,
        address token,
        uint32 dstEid,
        uint256 amountLD,
        address receiver,
        bytes memory composeMsg,
        uint128 composeGasLimit
    )
        internal
        view
        returns (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee)
    {
        bytes memory extraOptions = composeMsg.length > 0
            ? OptionsBuilder.newOptions().addExecutorLzComposeOption({ _index: 0, _gas: composeGasLimit, _value: 0 })
            : bytes("");

        sendParam = SendParam({
            dstEid: dstEid,
            to: OFTComposeMsgCodec.addressToBytes32(receiver),
            amountLD: amountLD,
            minAmountLD: 0,
            extraOptions: extraOptions,
            composeMsg: composeMsg,
            oftCmd: ""
        });

        IStargate _stargatePool = IStargate(poolAddress);

        (,, OFTReceipt memory receipt) = _stargatePool.quoteOFT({ _sendParam: sendParam });
        sendParam.minAmountLD = receipt.amountReceivedLD;

        messagingFee = _stargatePool.quoteSend({ _sendParam: sendParam, _payInLzToken: false });
        valueToSend = messagingFee.nativeFee;

        if (token == address(0)) {
            unchecked {
                valueToSend += sendParam.amountLD;
            }
        }
    }
}
