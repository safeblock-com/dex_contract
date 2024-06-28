// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { BaseOwnableFacet } from "../BaseOwnableFacet.sol";

import { TransferHelper } from "../libraries/TransferHelper.sol";

import { IStargate, SendParam, MessagingFee } from "./stargate/IStargate.sol";
import { OFTLimit, OFTFeeDetail, OFTReceipt } from "./stargate/IOFT.sol";
import { ILayerZeroComposer } from "./stargate/ILayerZeroComposer.sol";

import { OptionsBuilder } from "./libraries/OptionsBuilder.sol";
import { OFTComposeMsgCodec } from "./libraries/OFTComposeMsgCodec.sol";

contract StargateFacet is BaseOwnableFacet, ILayerZeroComposer {
    using OptionsBuilder for bytes;
    using TransferHelper for address;

    address private immutable _endpoint;

    event ReceivedOnDestination(address token);

    // =========================
    // events
    // =========================

    event CallFailed(bytes errorMessage);

    // =========================
    // errors
    // =========================

    error NotLZEndpoint();

    // =========================
    // constructor
    // =========================

    constructor(address endpoint) {
        _endpoint = endpoint;
    }

    // =========================
    // getters
    // =========================

    function lzEndpoint() external view returns (address) {
        return _endpoint;
    }

    // =========================
    // quoter
    // =========================

    function prepareTransferAndCall(
        address stargatePool,
        uint32 dstEid,
        uint256 amount,
        address composer,
        bytes memory composeMsg,
        uint128 composeGasLimit
    )
        external
        view
        returns (address token, uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee)
    {
        return _prepareTransferAndCall(stargatePool, dstEid, amount, composer, composeMsg, composeGasLimit);
    }

    // =========================
    // send
    // =========================

    function sendStargate(
        address stargatePool,
        uint32 destinationEndpointId,
        uint256 amount,
        address composer,
        uint128 composeGasLimit,
        bytes memory composeMsg,
        address refundAddress
    )
        external
        payable
    {
        (address token, uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) =
            _prepareTransferAndCall(stargatePool, destinationEndpointId, amount, composer, composeMsg, composeGasLimit);

        if (token > address(0)) {
            token.safeTransferFrom(msg.sender, address(this), amount);
            token.safeApprove(stargatePool, amount);
        }

        IStargate _stargatePool = IStargate(stargatePool);

        _stargatePool.sendToken{ value: valueToSend }(sendParam, messagingFee, refundAddress);
    }

    // =========================
    // receive
    // =========================

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
        if (msg.sender != _endpoint) {
            revert NotLZEndpoint();
        }

        uint256 amountLD = OFTComposeMsgCodec.amountLD(message);
        bytes memory composeMessage = OFTComposeMsgCodec.composeMsg(message);

        (address asset, address fallbackAddress, bytes32 argOverride, bytes memory payload) =
            abi.decode(composeMessage, (address, address, bytes32, bytes));

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
            emit CallFailed(payload);

            if (asset == address(0)) {
                TransferHelper.safeTransferNative({ to: fallbackAddress, value: amountLD });
            } else {
                TransferHelper.safeTransfer({ token: asset, to: fallbackAddress, value: amountLD });
            }
        }
    }

    // =========================
    // internal
    // =========================

    function _prepareTransferAndCall(
        address stargatePool,
        uint32 dstEid,
        uint256 amount,
        address composer,
        bytes memory composeMsg,
        uint128 composeGasLimit
    )
        internal
        view
        returns (address token, uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee)
    {
        bytes memory extraOptions = composeMsg.length > 0
            ? OptionsBuilder.newOptions().addExecutorLzComposeOption(0, composeGasLimit, 0) // compose gas limit
            : bytes("");

        sendParam = SendParam({
            dstEid: dstEid,
            to: OFTComposeMsgCodec.addressToBytes32(composer),
            amountLD: amount,
            minAmountLD: amount,
            extraOptions: extraOptions,
            composeMsg: composeMsg,
            oftCmd: ""
        });

        IStargate _stargatePool = IStargate(stargatePool);

        (,, OFTReceipt memory receipt) = _stargatePool.quoteOFT(sendParam);
        sendParam.minAmountLD = receipt.amountReceivedLD;

        messagingFee = _stargatePool.quoteSend(sendParam, false);
        valueToSend = messagingFee.nativeFee;

        token = _stargatePool.token();
        if (token == address(0)) {
            valueToSend += sendParam.amountLD;
        }
    }
}
