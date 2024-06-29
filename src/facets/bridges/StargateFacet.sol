// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { BaseOwnableFacet } from "../BaseOwnableFacet.sol";

import { TransferHelper } from "../libraries/TransferHelper.sol";

import { IStargate, SendParam, MessagingFee } from "./stargate/IStargate.sol";
import { OFTLimit, OFTFeeDetail, OFTReceipt } from "./stargate/IOFT.sol";
import { ILayerZeroComposer } from "./stargate/ILayerZeroComposer.sol";

import { OptionsBuilder } from "./libraries/OptionsBuilder.sol";
import { OFTComposeMsgCodec } from "./libraries/OFTComposeMsgCodec.sol";

import { IStargateComposer } from "./stargate/IStargateComposer.sol";
import { IStargateFactory } from "./stargate/IStargateFactory.sol";
import { IStargatePool } from "./stargate/IStargatePool.sol";

contract StargateFacet is BaseOwnableFacet, ILayerZeroComposer {
    using OptionsBuilder for bytes;
    using TransferHelper for address;

    address private immutable _lzEndpointV2;

    /// @dev Address of the stargate composer for cross-chain messaging
    IStargateComposer private immutable _stargateComposer;

    // =========================
    // events
    // =========================

    event CallFailed(bytes errorMessage);

    // =========================
    // errors
    // =========================

    error NotLZEndpoint();
    error StargateFacet_InvalidMsgValue();
    error NotStargateComposer();

    // =========================
    // constructor
    // =========================

    constructor(address endpointV2, address stargateComposer) {
        _lzEndpointV2 = endpointV2;
        _stargateComposer = IStargateComposer(stargateComposer);
    }

    // =========================
    // getters
    // =========================

    function lzEndpoint() external view returns (address) {
        return _lzEndpointV2;
    }

    function stargateV1Composer() external view returns (IStargateComposer) {
        return _stargateComposer;
    }

    // =========================
    // quoter
    // =========================

    function quoteV1(
        uint16 dstChainId,
        address composer,
        bytes memory payload,
        IStargateComposer.lzTxObj calldata lzTxParams
    )
        external
        view
        returns (uint256)
    {
        return _quoteV1(dstChainId, composer, payload, lzTxParams);
    }

    function quoteV2(
        address stargatePool,
        uint32 dstEid,
        uint256 amount,
        address composer,
        bytes memory composeMsg,
        uint128 composeGasLimit
    )
        external
        view
        returns (uint256 valueToSend)
    {
        (, valueToSend,,) = _quoteV2(stargatePool, dstEid, amount, composer, composeMsg, composeGasLimit);
    }

    // =========================
    // send
    // =========================

    function sendStargateV1(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        uint256 amount,
        uint256 amountOutMinSg,
        address receiver,
        bytes memory payload,
        IStargateComposer.lzTxObj calldata lzTxParams
    )
        external
        payable
    {
        uint256 fee = _quoteV1(dstChainId, receiver, payload, lzTxParams);

        bool isEth = _stargateComposer.stargateEthVaults(srcPoolId) > address(0);

        if (isEth) {
            unchecked {
                fee += amount;
            }
        } else {
            address token =
                IStargatePool(IStargateFactory(_stargateComposer.factory()).getPool({ poolId: srcPoolId })).token();
            token.safeTransferFrom({ from: msg.sender, to: address(this), value: amount });
            token.safeApprove({ spender: address(_stargateComposer), value: amount });
        }
        _validateMsgValue(fee);

        _stargateComposer.swap{ value: fee }({
            dstChainId: dstChainId,
            srcPoolId: srcPoolId,
            dstPoolId: dstPoolId,
            refundAddress: payable(msg.sender),
            amountLD: amount,
            minAmountLD: amountOutMinSg,
            lzTxParams: lzTxParams,
            to: abi.encodePacked(receiver),
            payload: payload
        });
    }

    function sendStargateV2(
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
            _quoteV2(stargatePool, destinationEndpointId, amount, composer, composeMsg, composeGasLimit);

        _validateMsgValue(valueToSend);

        if (token > address(0)) {
            token.safeTransferFrom({ from: msg.sender, to: address(this), value: amount });
            token.safeApprove({ spender: stargatePool, value: amount });
        }

        IStargate(stargatePool).sendToken{ value: valueToSend }({
            sendParam: sendParam,
            fee: messagingFee,
            refundAddress: refundAddress
        });
    }

    // =========================
    // receive
    // =========================

    function sgReceive(
        uint16, /* srcEid */
        bytes memory, /* srcSender */
        uint256, /* nonce */
        address asset,
        uint256 amountLD,
        bytes calldata message
    )
        external
        payable
    {
        if (msg.sender != address(_stargateComposer)) {
            revert NotStargateComposer();
        }

        (address fallbackAddress, bytes32 argOverride, bytes memory payload) =
            abi.decode(message, (address, bytes32, bytes));

        _sendCallback(asset, amountLD, fallbackAddress, argOverride, payload);
    }

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
            revert NotLZEndpoint();
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
            emit CallFailed(payload);

            if (asset == address(0)) {
                TransferHelper.safeTransferNative({ to: fallbackAddress, value: amountLD });
            } else {
                TransferHelper.safeTransfer({ token: asset, to: fallbackAddress, value: amountLD });
            }
        }
    }

    function _validateMsgValue(uint256 value) internal view {
        if (msg.value < value) {
            revert StargateFacet_InvalidMsgValue();
        }
    }

    function _quoteV1(
        uint16 dstChainId,
        address receiver,
        bytes memory payload,
        IStargateComposer.lzTxObj calldata lzTxParams
    )
        internal
        view
        returns (uint256 valueToSend)
    {
        (valueToSend,) = _stargateComposer.quoteLayerZeroFee({
            _dstChainId: dstChainId,
            functionType: 1,
            toAddress: abi.encodePacked(receiver),
            transferAndCallPayload: payload,
            lzTxParams: lzTxParams
        });
    }

    function _quoteV2(
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
            ? OptionsBuilder.newOptions().addExecutorLzComposeOption({
                _index: 0,
                _gas: composeGasLimit, // compose gas limit
                _value: 0
            })
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

        (,, OFTReceipt memory receipt) = _stargatePool.quoteOFT({ _sendParam: sendParam });
        sendParam.minAmountLD = receipt.amountReceivedLD;

        messagingFee = _stargatePool.quoteSend({ _sendParam: sendParam, _payInLzToken: false });
        valueToSend = messagingFee.nativeFee;

        token = _stargatePool.token();
        if (token == address(0)) {
            valueToSend += sendParam.amountLD;
        }
    }
}
