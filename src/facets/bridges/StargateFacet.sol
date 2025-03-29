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
import { FeeLibrary } from "../../libraries/FeeLibrary.sol";

import { IStargateFacet } from "./interfaces/IStargateFacet.sol";

/// @title StargateFacet
/// @notice A stargate facet for cross-chain messaging and token bridging
contract StargateFacet is BaseOwnableFacet, ILayerZeroComposer, IStargateFacet {
    using OptionsBuilder for bytes;

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
        uint256 amountLD,
        address receiver,
        uint128 composeGasLimit,
        bytes memory composeMsg
    )
        external
    {
        address token = IStargate(poolAddress).token();
        address sender = TransientStorageFacetLibrary.getSenderAddress();

        if (token > address(0)) {
            uint256 amount = TransientStorageFacetLibrary.getAmountForToken({ token: token });
            if (amount == 0) {
                TransferHelper.safeTransferFrom({ token: token, from: sender, to: address(this), value: amountLD });
            } else {
                amountLD = amount;
            }
        } else {
            revert IStargateFacet.StargateFacet_UnsupportedAsset();
        }

        amountLD = FeeLibrary.payFee({ token: token, amount: amountLD });

        uint256 balanceBefore;
        if (token > address(0)) {
            balanceBefore = TransferHelper.safeGetBalance({ token: token, account: address(this) });
        }

        (uint256 valueToSend, SendParam memory sendParam, MessagingFee memory messagingFee) =
            _quoteV2(poolAddress, token, dstEid, amountLD, receiver, composeMsg, composeGasLimit);

        _validateNativeBalance(valueToSend);

        TransferHelper.safeApprove({ token: token, spender: poolAddress, value: amountLD });

        IStargate(poolAddress).sendToken{ value: valueToSend }({
            sendParam: sendParam,
            fee: messagingFee,
            refundAddress: sender
        });

        unchecked {
            uint256 balanceAfter =
                amountLD - (balanceBefore - TransferHelper.safeGetBalance({ token: token, account: address(this) }));

            TransientStorageFacetLibrary.setAmountForToken({ token: token, amount: balanceAfter, record: true });
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

    /// @dev Send callback to this address for execute cross chain message.
    function _sendCallback(address asset, uint256 amountLD, address fallbackAddress, bytes memory payload) internal {
        if (asset > address(0)) {
            TransientStorageFacetLibrary.setAmountForToken({ token: asset, amount: amountLD, record: false });

            bool successfulCall;
            assembly ("memory-safe") {
                successfulCall := call(gas(), address(), 0, add(payload, 32), mload(payload), 0, 0)

                if iszero(successfulCall) {
                    returndatacopy(add(payload, 32), 0, returndatasize())
                    mstore(payload, returndatasize())
                }
            }

            if (!successfulCall) {
                // zero the temporary value in storage
                amountLD = FeeLibrary.payFee({
                    token: asset,
                    amount: TransientStorageFacetLibrary.getAmountForToken({ token: asset })
                });

                emit IStargateFacet.CallFailed({ errorMessage: payload });

                TransferHelper.safeTransfer({ token: asset, to: fallbackAddress, value: amountLD });
            }
        } else {
            TransferHelper.safeTransferNative({ to: fallbackAddress, value: amountLD });
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

        if (token == address(0)) {
            unchecked {
                valueToSend += sendParam.amountLD;
            }
        }
    }
}
