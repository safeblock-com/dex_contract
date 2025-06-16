// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { BaseOwnableFacet } from "../BaseOwnableFacet.sol";

import { TransferHelper } from "../../libraries/TransferHelper.sol";

import { TransientStorageFacetLibrary } from "../../libraries/TransientStorageFacetLibrary.sol";
import { FeeLibrary } from "../../libraries/FeeLibrary.sol";

import { IV3SpokePool } from "./interfaces/IV3SpokePool.sol";
import { IAcrossFacet } from "./interfaces/IAcrossFacet.sol";

import { E18 } from "../../libraries/Constants.sol";

/// @title AcrossFacet
/// @notice A facet for cross-chain token bridging and message passing via the Across V3 protocol in a diamond-like proxy contract.
/// @dev Supports depositing tokens for cross-chain transfer and handling incoming messages with callbacks.
contract AcrossFacet is BaseOwnableFacet, IAcrossFacet {
    // =========================
    // storage
    // =========================

    /// @dev The address of the Across V3 SpokePool contract.
    ///      Immutable, set during construction. Used for depositing tokens and validating incoming messages.
    address private immutable _spokePool;

    /// @dev The address of the wrapped native token (e.g., WETH).
    ///      Immutable, set during construction. Used for native currency deposits.
    address private immutable _wrappedNative;

    // =========================
    // constructor
    // =========================

    /// @notice Initializes the AcrossFacet with the SpokePool and wrapped native token addresses.
    /// @dev Sets the immutable `_spokePool` and `_wrappedNative` addresses.
    /// @param spokePool_ The address of the Across V3 SpokePool contract.
    /// @param wrappedNative_ The address of the wrapped native token (e.g., WETH).
    constructor(address spokePool_, address wrappedNative_) {
        _spokePool = spokePool_;
        _wrappedNative = wrappedNative_;
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
    function sendAcrossDepositV3(IAcrossFacet.V3AcrossDepositParams calldata acrossDepositParams) external {
        address inputToken = acrossDepositParams.inputToken;
        uint256 inputAmount = acrossDepositParams.inputAmount;

        address sender = TransientStorageFacetLibrary.getSenderAddress();
        uint256 nativeValue;
        if (inputToken > address(0)) {
            uint256 amount = TransientStorageFacetLibrary.getAmountForToken({ token: inputToken });
            if (amount == 0) {
                TransferHelper.safeTransferFrom({
                    token: inputToken,
                    from: sender,
                    to: address(this),
                    value: inputAmount
                });
            } else {
                inputAmount = amount;
            }
            TransferHelper.safeApprove({ token: inputToken, spender: address(_spokePool), value: inputAmount });
        } else {
            inputToken = _wrappedNative;
            nativeValue = inputAmount;
        }

        bytes memory depositCalldata = _getDepositV3Calldata(sender, acrossDepositParams, inputToken, inputAmount);
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

        TransientStorageFacetLibrary.setAmountForToken({ token: tokenSent, amount: amount, record: false });

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
            amount = TransientStorageFacetLibrary.getAmountForToken({ token: tokenSent });

            emit IAcrossFacet.CallFailed({ errorMessage: payload });

            TransferHelper.safeTransfer({ token: tokenSent, to: fallbackAddress, value: amount });
        }
    }

    // =========================
    // internal functions
    // =========================

    /// @dev Constructs the calldata for the `depositV3` call to the SpokePool.
    ///      Encodes the deposit parameters, adjusting the output amount based on `outputAmountPercent` scaled by `E18`.
    /// @param sender The depositor address.
    /// @param acrossDepositParams The deposit parameters.
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
                    inputAmount * acrossDepositParams.outputAmountPercent / E18, // outPutAmount
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
}
