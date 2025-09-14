// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Utils } from "../../libraries/Utils.sol";
import { TransferHelper } from "../../libraries/TransferHelper.sol";
import { TransientStorageLibrary } from "../../libraries/TransientStorageLibrary.sol";

import { LayerZeroLib } from "../../libraries/LayerZeroLib.sol";

import { IV3SpokePool } from "./interfaces/IV3SpokePool.sol";
import { IAcrossFacet } from "./interfaces/IAcrossFacet.sol";
import { ILayerZeroEndpointV2 } from "../stargateFacet/interfaces/ILayerZeroEndpointV2.sol";

import { E18 } from "../../libraries/Constants.sol";

/// @title AcrossFacet
/// @notice A facet for cross-chain token bridging and message passing via the Across V3 protocol in a diamond-like proxy contract
/// @dev Supports depositing tokens for cross-chain transfer and handling incoming messages with callbacks.
///      This facet is part of the diamond proxy pattern and provides functionality for cross-chain token bridging
///      using the Across V3 protocol. It integrates with the EntryPoint contract to route calls appropriately.
contract AcrossFacet is IAcrossFacet {
    // =========================
    // storage
    // =========================

    /// @dev The address of the Across V3 SpokePool contract.
    ///      Immutable, set during construction. Used for depositing tokens and validating incoming messages.
    address private immutable _spokePool;

    /// @dev The address of the wrapped native token (e.g., WETH).
    ///      Immutable, set during construction. Used for native currency deposits.
    address private immutable _wrappedNative;

    /// @dev The address of the LayerZero V2 endpoint contract.
    ///      Immutable, set during construction. Used for validating incoming compose messages in `lzCompose`.
    address private immutable _lzEndpointV2;

    // =========================
    // constructor
    // =========================

    /// @notice Initializes the AcrossFacet with the SpokePool and wrapped native token addresses.
    /// @dev Sets the immutable `_spokePool` and `_wrappedNative` addresses.
    /// @param spokePool_ The address of the Across V3 SpokePool contract.
    /// @param wrappedNative_ The address of the wrapped native token (e.g., WETH).
    constructor(address spokePool_, address wrappedNative_, address endpointV2) {
        _spokePool = spokePool_;
        _wrappedNative = wrappedNative_;
        _lzEndpointV2 = endpointV2;
    }

    // =========================
    // getters
    // =========================

    /// @inheritdoc IAcrossFacet
    function spokePool() external view returns (address) {
        return _spokePool;
    }

    // =========================
    // main logic
    // =========================

    /// @inheritdoc IAcrossFacet
    function sendAcrossDepositV3(IAcrossFacet.V3AcrossDepositParams calldata acrossDepositParams)
        external
        returns (bytes32[] memory tokensAndAmounts)
    {
        address inputToken = acrossDepositParams.inputToken;
        uint256 inputAmount;

        tokensAndAmounts = Utils.decodeTokensAndAmountsArray();

        uint256 nativeValue;
        if (inputToken > address(0)) {
            inputAmount = Utils.getAmountFromArrayAndDelete({ tokensAndAmounts: tokensAndAmounts, token: inputToken });
            Utils.expectNotZero({ value: inputAmount });

            TransferHelper.safeApprove({ token: inputToken, spender: address(_spokePool), value: inputAmount });
        } else {
            inputToken = _wrappedNative;
            nativeValue = inputAmount;
        }

        bytes memory depositCalldata = _getDepositV3Calldata(
            TransientStorageLibrary.getSenderAddress(), acrossDepositParams, inputToken, inputAmount
        );
        address spokePool_ = _spokePool;

        assembly ("memory-safe") {
            if iszero(call(gas(), spokePool_, nativeValue, add(depositCalldata, 32), mload(depositCalldata), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function sendAcrossDeposit(IAcrossFacet.AcrossDepositParams calldata acrossDepositParams)
        external
        returns (bytes32[] memory tokensAndAmounts)
    {
        address inputToken = acrossDepositParams.inputToken;
        uint256 inputAmount;

        tokensAndAmounts = Utils.decodeTokensAndAmountsArray();

        uint256 nativeValue;
        if (inputToken > address(0)) {
            inputAmount = Utils.getAmountFromArrayAndDelete({ tokensAndAmounts: tokensAndAmounts, token: inputToken });
            Utils.expectNotZero({ value: inputAmount });

            TransferHelper.safeApprove({ token: inputToken, spender: _spokePool, value: inputAmount });
        } else {
            inputToken = _wrappedNative;
            nativeValue = inputAmount;
        }

        bytes memory depositCalldata = _getDepositV3Calldata(
            TransientStorageLibrary.getSenderAddress(),
            acrossDepositParams.recipient,
            acrossDepositParams,
            inputToken,
            inputAmount
        );

        address spokePool_ = _spokePool;
        assembly ("memory-safe") {
            if iszero(call(gas(), spokePool_, nativeValue, add(depositCalldata, 32), mload(depositCalldata), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /// @inheritdoc IAcrossFacet
    function handleV3AcrossMessage(
        address tokenSent,
        uint256 amount,
        address, /* relayer */
        bytes memory message
    )
        external
    {
        if (msg.sender != _spokePool) {
            revert IAcrossFacet.AcrossFacet_NotSpokePool();
        }

        (address fallbackAddress, bytes memory payload) = abi.decode(message, (address, bytes));

        bool successfulCall;
        assembly ("memory-safe") {
            let length := mload(payload)
            let offset := add(payload, add(32, length))
            mstore(offset, add(shl(160, amount), tokenSent))
            mstore(add(offset, 32), 1)
            length := add(length, 64)

            successfulCall := call(gas(), address(), 0, add(payload, 32), length, 0, 0)

            if iszero(successfulCall) {
                returndatacopy(add(payload, 32), 0, returndatasize())
                mstore(payload, returndatasize())
            }
        }

        if (!successfulCall) {
            emit IAcrossFacet.CallFailed({ errorMessage: payload });
            TransferHelper.safeTransfer({ token: tokenSent, to: fallbackAddress, value: amount });
        }
    }

    // =========================
    // internal functions
    // =========================

    /// @notice Constructs the calldata for the `depositV3` call to the SpokePool
    /// @dev Encodes the deposit parameters, adjusting the output amount based on `outputAmountPercent` scaled by `E18`.
    /// @param sender The depositor address.
    /// @param acrossDepositParams The deposit parameters including:
    ///        - recipient: The recipient address on the destination chain
    ///        - inputToken: The input token address (address(0) for native currency)
    ///        - outputToken: The output token address on the destination chain
    ///        - outputAmountPercent: The percentage of input amount to receive on the destination chain
    ///        - destinationChainId: The destination chain ID
    ///        - exclusiveRelayer: The exclusive relayer address
    ///        - quoteTimestamp: The timestamp of the quote
    ///        - fillDeadline: The deadline for filling the deposit
    ///        - exclusivityDeadline: The deadline for exclusive relayer
    ///        - message: Additional message data
    /// @param inputToken The input token address (adjusted to `_wrappedNative` for native deposits).
    /// @param inputAmount The input token amount.
    /// @return The encoded calldata for `IV3SpokePool.depositV3`.
    function _getDepositV3Calldata(
        address sender,
        IAcrossFacet.V3AcrossDepositParams calldata acrossDepositParams,
        address inputToken,
        uint256 inputAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        unchecked {
            return abi.encodeCall(
                IV3SpokePool.depositV3,
                (
                    sender, // depositor
                    acrossDepositParams.recipient,
                    inputToken,
                    acrossDepositParams.outputToken,
                    inputAmount,
                    inputAmount * acrossDepositParams.outputAmountPercent / E18, // outputAmount
                    acrossDepositParams.destinationChainId,
                    acrossDepositParams.exclusiveRelayer,
                    acrossDepositParams.quoteTimestamp,
                    acrossDepositParams.fillDeadline,
                    acrossDepositParams.exclusivityDeadline,
                    abi.encode(sender, acrossDepositParams.message) // fallbackAddress and message
                )
            );
        }
    }

    /// @notice Constructs the calldata for the `depositV3` call to the SpokePool and optionally send cross-chain message via LayerZero
    /// @dev Encodes the deposit parameters, adjusting the output amount based on `outputAmountPercent` scaled by `E18`.
    /// @param sender The depositor address.
    /// @param acrossDepositParams The deposit parameters including:
    ///        - recipient: The recipient address on the destination chain
    ///        - inputToken: The input token address (address(0) for native currency)
    ///        - outputToken: The output token address on the destination chain
    ///        - outputAmountPercent: The percentage of input amount to receive on the destination chain
    ///        - destinationChainId: The destination chain ID
    ///        - exclusiveRelayer: The exclusive relayer address
    ///        - quoteTimestamp: The timestamp of the quote
    ///        - fillDeadline: The deadline for filling the deposit
    ///        - exclusivityDeadline: The deadline for exclusive relayer
    ///        - message: Additional message data
    /// @param inputToken The input token address (adjusted to `_wrappedNative` for native deposits).
    /// @param inputAmount The input token amount.
    /// @return The encoded calldata for `IV3SpokePool.depositV3`.
    function _getDepositV3Calldata(
        address sender,
        address recipient,
        IAcrossFacet.AcrossDepositParams calldata acrossDepositParams,
        address inputToken,
        uint256 inputAmount
    )
        internal
        returns (bytes memory)
    {
        unchecked {
            address outputToken = acrossDepositParams.outputToken;
            uint256 outputAmount = inputAmount * acrossDepositParams.outputAmountPercent / E18;

            recipient = LayerZeroLib.validateReceiver({
                receiver: acrossDepositParams.recipient,
                sender: sender,
                dstEid: acrossDepositParams.dstEid,
                tokenIn: inputToken,
                tokenOut: outputToken,
                minAmountLD: outputAmount,
                extraData: acrossDepositParams.extraData,
                endpoint: ILayerZeroEndpointV2(_lzEndpointV2)
            });

            return abi.encodeCall(
                IV3SpokePool.depositV3,
                (
                    sender, // depositor
                    recipient,
                    inputToken,
                    outputToken,
                    inputAmount,
                    outputAmount,
                    acrossDepositParams.destinationChainId,
                    acrossDepositParams.exclusiveRelayer,
                    acrossDepositParams.quoteTimestamp,
                    acrossDepositParams.fillDeadline,
                    acrossDepositParams.exclusivityDeadline,
                    new bytes(0)
                )
            );
        }
    }
}
