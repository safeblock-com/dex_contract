// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IWrappedNative } from "../interfaces/IWrappedNative.sol";
import { TransferHelper } from "../libraries/TransferHelper.sol";

import { IConnext } from "./connext/IConnext.sol";

import { BaseOwnableFacet } from "../BaseOwnableFacet.sol";

import { IXReceiver } from "./connext/IXReceiver.sol";

contract ConnextFacet is BaseOwnableFacet, IXReceiver {
    using TransferHelper for address;

    address private immutable _wrappedNative;

    IConnext private immutable _connext;

    constructor(address wrappedNative, address connext) {
        _wrappedNative = wrappedNative;
        _connext = IConnext(connext);
    }

    /// ERRORS
    error ForwarderXReceiver__onlyConnext(address sender);
    error ForwarderXReceiver__prepareAndForward_notThis(address sender);

    /**
     * @notice A modifier to ensure that only the Connext contract on this domain can be the caller.
     * If this is not enforced, then funds on this contract may potentially be claimed by any EOA.
     */
    modifier onlyConnext() {
        if (msg.sender != address(_connext)) {
            revert ForwarderXReceiver__onlyConnext(msg.sender);
        }
        _;
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
    function xTransferAndCall(
        address token,
        uint256 amount,
        address recipient,
        uint32 destinationDomain,
        uint256 slippage,
        uint256 relayerFee,
        bytes32 argOverride,
        bytes calldata payload
    )
        external
        payable
    {
        if (TransferHelper.safeGetBalance({ token: token, account: address(this) }) < amount) {
            if (token == _wrappedNative) {
                IWrappedNative(_wrappedNative).deposit{ value: amount }();
            } else {
                token.safeTransferFrom({ from: msg.sender, to: address(this), value: amount });
            }
        }

        token.safeApprove({ spender: address(_connext), value: amount });

        _connext.xcall{ value: relayerFee }({
            destination: destinationDomain,
            to: recipient,
            asset: token,
            delegate: msg.sender,
            amount: amount,
            slippage: slippage,
            callData: abi.encode(msg.sender, argOverride, payload)
        });
    }

    event CallFailed(bytes32 transferId, bytes errorMessage);

    /**
     * @notice Receives funds from Connext and do with call with them.
     * @dev _originSender and _origin are not used in this implementation because this is meant for an "unauthenticated" call. This means
     * any router can call this function and no guarantees are made on the data passed in. This should only be used when there are
     * funds passed into the contract that need to be forwarded to another contract. This guarantees economically that there is no
     * reason to call this function maliciously, because the router would be spending their own funds.
     * @param transferId - The transfer ID of the transfer that triggered this call.
     * @param amount - The amount of funds received in this transfer.
     * @param asset - The asset of the funds received in this transfer.
     * @param callData - The data to be prepared and forwarded. Fallback address needs to be encoded in the data to be used in case the forward fails.
     */
    function xReceive(
        bytes32 transferId,
        uint256 amount, // Final amount received via Connext
        address asset,
        address, /*_originSender*/
        uint32, /*_origin*/
        bytes calldata callData
    )
        external
        onlyConnext
        returns (bytes memory)
    {
        (address fallbackAddress, bytes32 argOverride, bytes memory payload) =
            abi.decode(callData, (address, bytes32, bytes));

        bool successfulCall;
        assembly ("memory-safe") {
            if argOverride { mstore(add(payload, add(32, argOverride)), amount) }

            successfulCall := call(gas(), address(), 0, add(payload, 32), mload(payload), 0, 0)

            if iszero(successfulCall) {
                returndatacopy(add(payload, 32), 0, returndatasize())
                mstore(payload, returndatasize())
            }
        }

        if (!successfulCall) {
            emit CallFailed(transferId, payload);
            TransferHelper.safeTransfer({ token: asset, to: fallbackAddress, value: amount });
        }

        return abi.encode(successfulCall);
    }
}
