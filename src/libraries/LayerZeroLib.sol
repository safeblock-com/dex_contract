// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ILayerZeroEndpointV2, MessagingParams } from "../facets/stargateFacet/interfaces/ILayerZeroEndpointV2.sol";

import { Utils } from "./Utils.sol";
import { ADDRESS_MASK } from "./Constants.sol";
import { StorageLibrary } from "./StorageLibrary.sol";

/// @title LayerZeroLib
/// @notice Library for sending cross-chain messages using the LayerZero V2 protocol.
library LayerZeroLib {
    /// @dev Validates the recipient address for a cross-chain transfer.
    ///      If the recipient is not provided, sends the message through LayerZero.
    /// @param receiver The recipient address on the destination chain.
    /// @param sender The sender address.
    /// @param dstEid The destination chain’s LayerZero endpoint ID.
    /// @param tokenIn The address of the token to send.
    /// @param tokenOut The address of the token to receive on the destination chain.
    /// @param minAmountLD The minimum amount of tokens to receive on the destination chain.
    /// @param extraData Extra data to pass to the deposit address bytecode.
    /// @return receiver The validated recipient address.
    function validateReceiver(
        address receiver,
        address sender,
        uint32 dstEid,
        address tokenIn,
        address tokenOut,
        uint256 minAmountLD,
        bytes calldata extraData,
        ILayerZeroEndpointV2 endpoint
    )
        internal
        returns (address)
    {
        if (receiver == address(0)) {
            // send cross-chain message through LayerZero
            receiver = sendCrossChainMessage({
                sender: sender,
                endpoint: endpoint,
                remoteEid: dstEid,
                trustedPeer: getPeer({ remoteEid: dstEid }),
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                minimalAmountOut: minAmountLD,
                extraData: extraData
            });
        }

        return receiver;
    }

    /// @dev Sends a cross-chain message using the LayerZero V2 protocol.
    /// @param sender The sender address.
    /// @param endpoint The LayerZero endpoint.
    /// @param remoteEid The remote chain's endpoint ID.
    /// @param trustedPeer The trusted peer address.
    /// @param tokenIn The token to send.
    /// @param tokenOut The token to receive on the destination chain.
    /// @param minimalAmountOut The minimum amount of tokens to receive on the destination chain.
    /// @param extraData Extra data to pass to the deposit address bytecode.
    /// @return depositAddress The calculated deposit address.
    function sendCrossChainMessage(
        address sender,
        ILayerZeroEndpointV2 endpoint,
        uint32 remoteEid,
        bytes32 trustedPeer,
        address tokenIn,
        address tokenOut,
        uint256 minimalAmountOut,
        bytes calldata extraData
    )
        internal
        returns (address depositAddress)
    {
        bytes memory message;
        {
            uint256 nonce;
            unchecked {
                nonce = StorageLibrary.getLayerZeroFacetStorage().nonce[remoteEid]++;
            }

            depositAddress = calculateDepositAddress({
                sender: sender,
                nonce: nonce,
                trustedPeer: trustedPeer,
                extraData: extraData
            });

            message =
                abi.encode(depositAddress, sender, nonce, block.chainid, tokenIn, tokenOut, minimalAmountOut, extraData);
        }

        bytes memory options = getLzReceiveOptions();

        uint256 fee = quote({
            endpoint: endpoint,
            remoteEid: remoteEid,
            trustedPeer: trustedPeer,
            message: message,
            options: options
        });

        Utils.compareAmounts({ greaterValue: address(this).balance, lowerValue: fee });

        endpoint.send{ value: fee }({
            params: MessagingParams({
                dstEid: remoteEid,
                receiver: trustedPeer,
                message: message,
                options: options,
                payInLzToken: false
            }),
            refundAddress: address(this)
        });
    }

    /// @dev Calculates the deposit address for receiving tokens on the destination chain.
    ///      The address is calculated using the sender address, source chain ID, nonce, trusted peer, and extra data.
    /// @param sender The sender address of the transaction.
    /// @param nonce The nonce of the transaction for the remote chain.
    /// @param trustedPeer The trusted peer address on the remote chain.
    /// @param extraData Extra data to pass to the deposit address bytecode.
    /// @return depositAddress The calculated deposit address.
    function calculateDepositAddress(
        address sender,
        uint256 nonce,
        bytes32 trustedPeer,
        bytes calldata extraData
    )
        internal
        view
        returns (address depositAddress)
    {
        bytes memory bytecode = abi.encodePacked(
            hex"608160113439333d60010152608134f3fe7f00000000000000000000000000000000000000000000000000000000000000003381146029575b005b3680600014607057602014603c575b6027565b60006044601c8280948135906370a0823183523060205260206040602486855afa5063a9059cbb83526020525af150386038565b5060008080809347905af15038603856",
            extraData
        );

        assembly ("memory-safe") {
            mstore(0, sender)
            mstore(32, add(shl(32, nonce), chainid()))

            let salt := keccak256(0, 64)

            mstore(0, add(shl(248, 0xff), shl(88, trustedPeer)))
            mstore(21, salt)
            mstore(53, keccak256(add(bytecode, 32), mload(bytecode))) // bytecode hash

            depositAddress := and(keccak256(0, 85), ADDRESS_MASK)

            mstore(64, bytecode)
        }
    }

    /// @dev Returns the options for a LayerZero receive message.
    function getLzReceiveOptions() internal pure returns (bytes memory options) {
        // uint16(3) - type
        // uint8(1) - worker id
        // uint16(17) - payload length
        // uint8(1) - lzReceive type
        // uint128(75000) - gasLimit
        options = hex"000301001101000000000000000000000000000124f8";
    }

    /// @dev Returns the fee for a LayerZero message in native currency.
    /// @param endpoint The LayerZero endpoint.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @param trustedPeer The trusted peer address.
    /// @param message The message data.
    /// @param options The message options.
    function quote(
        ILayerZeroEndpointV2 endpoint,
        uint32 remoteEid,
        bytes32 trustedPeer,
        bytes memory message,
        bytes memory options
    )
        internal
        view
        returns (uint256 nativeFee)
    {
        nativeFee = endpoint.quote({
            params: MessagingParams({
                dstEid: remoteEid,
                receiver: trustedPeer,
                message: message,
                options: options,
                payInLzToken: false
            }),
            sender: address(this)
        }).nativeFee;
    }

    /// @dev Retrieves the trusted peer address for a remote endpoint ID.
    ///      Returns the stored peer from the `peers` mapping or `address(this)` if unset.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @return trustedRemote The trusted peer address (bytes32).
    function getPeer(uint32 remoteEid) internal view returns (bytes32 trustedRemote) {
        trustedRemote = StorageLibrary.getLayerZeroFacetStorage().peers[remoteEid];
        if (trustedRemote == 0) {
            assembly ("memory-safe") {
                trustedRemote := address()
            }
        }
    }
}
