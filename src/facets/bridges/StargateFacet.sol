// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { BaseOwnableFacet } from "../BaseOwnableFacet.sol";

import { TransferHelper } from "../libraries/TransferHelper.sol";

import { IStargate, SendParam, MessagingFee } from "./stargate/IStargate.sol";
import { OFTLimit, OFTFeeDetail, OFTReceipt } from "./stargate/IOFT.sol";
import { ILayerZeroComposer } from "./stargate/ILayerZeroComposer.sol";

import { OptionsBuilder } from "./libraries/OptionsBuilder.sol";
import { OFTComposeMsgCodec } from "./libraries/OFTComposeMsgCodec.sol";

import { TransientStorageFacetLibrary } from "../../libraries/TransientStorageFacetLibrary.sol";

import { IStargateFacet } from "./interfaces/IStargateFacet.sol";

/// @title StargateFacet
/// @notice A stargate facet for cross-chain messaging and token bridging
contract StargateFacet is BaseOwnableFacet, ILayerZeroComposer, IStargateFacet {
    using OptionsBuilder for bytes;
    using TransferHelper for address;

    /// @dev Address of the layerZero endpoint
    address private immutable _lzEndpointV2;

    // =========================
    // constructor
    // =========================

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
        (, valueToSend, sendParam,) = _quoteV2(poolAddress, dstEid, amountLD, receiver, composeMsg, composeGasLimit);

        dstAmount = sendParam.minAmountLD;
    }

    // =========================
    // send
    // =========================

    /// @inheritdoc IStargateFacet
    function sendStargateV2(
        address poolAddress,
        uint32 dstEid,
        uint256 amountLD,
        address receiver,
        uint128 composeGasLimit,
        bytes memory composeMsg
    )
        external
        payable
        returns (uint256)
    {
        (address token, uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) =
            _quoteV2(poolAddress, dstEid, amountLD, receiver, composeMsg, composeGasLimit);

        _validateNativeBalance(valueToSend);

        address sender = TransientStorageFacetLibrary.getSenderAddress();

        uint256 balanceBefore;

        if (token > address(0)) {
            balanceBefore = token.safeGetBalance({ account: address(this) });

            if (balanceBefore < amountLD) {
                token.safeTransferFrom({ from: sender, to: address(this), value: amountLD });
                balanceBefore = token.safeGetBalance({ account: address(this) });
            }

            token.safeApprove({ spender: poolAddress, value: amountLD });
        }

        IStargate(poolAddress).sendToken{ value: valueToSend }({
            sendParam: sendParam,
            fee: messagingFee,
            refundAddress: sender
        });

        if (token == address(0)) {
            return 0;
        } else {
            unchecked {
                return amountLD - (balanceBefore - token.safeGetBalance({ account: address(this) }));
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
            revert IStargateFacet.NotLZEndpoint();
        }

        uint256 amountLD = OFTComposeMsgCodec.amountLD({ _msg: message });
        bytes memory composeMessage = OFTComposeMsgCodec.composeMsg({ _msg: message });

        (address asset, address fallbackAddress, bytes32 argOverride, bytes memory payload) =
            abi.decode(composeMessage, (address, address, bytes32, bytes));

        _sendCallback(asset, amountLD, fallbackAddress, argOverride, payload);
    }

    // =========================
    // internal
    // =========================

    /// @dev Send callback to this address for execute cross chain message.
    function _sendCallback(
        address asset,
        uint256 amountLD,
        address fallbackAddress,
        bytes32 argOverride,
        bytes memory payload
    )
        internal
    {
        bool successfulCall;
        assembly ("memory-safe") {
            if argOverride { mstore(add(payload, add(32, argOverride)), amountLD) }

            successfulCall := call(gas(), address(), 0, add(payload, 32), mload(payload), 0, 0)

            if iszero(successfulCall) {
                returndatacopy(add(payload, 32), 0, returndatasize())
                mstore(payload, returndatasize())
            }
        }

        if (!successfulCall) {
            emit CallFailed({ errorMessage: payload });

            if (asset == address(0)) {
                TransferHelper.safeTransferNative({ to: fallbackAddress, value: amountLD });
            } else {
                TransferHelper.safeTransfer({ token: asset, to: fallbackAddress, value: amountLD });
            }
        }
    }

    /// @dev Validate native balance.
    function _validateNativeBalance(uint256 value) internal view {
        if (address(this).balance < value) {
            revert IStargateFacet.StargateFacet_InvalidNativeBalance();
        }
    }

    /// @dev Quote fee for stargate V2.
    function _quoteV2(
        address poolAddress,
        uint32 dstEid,
        uint256 amountLD,
        address receiver,
        bytes memory composeMsg,
        uint128 composeGasLimit
    )
        internal
        view
        returns (address token, uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee)
    {
        bytes memory extraOptions = composeMsg.length > 0
            ? OptionsBuilder.newOptions().addExecutorLzComposeOption({
                _index: 0,
                _gas: composeGasLimit, // compose gas limit
                _value: 0
            })
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

        token = _stargatePool.token();
        if (token == address(0)) {
            unchecked {
                valueToSend += sendParam.amountLD;
            }
        }
    }
}
