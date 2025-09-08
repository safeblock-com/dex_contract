// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    ILayerZeroEndpointV2,
    MessagingParams,
    MessagingFee
} from "../facets/stargateFacet/interfaces/ILayerZeroEndpointV2.sol";

import { Utils } from "./Utils.sol";
import { ADDRESS_MASK } from "./Constants.sol";
import { StorageLibrary, LayerZeroFacetStorage } from "./StorageLibrary.sol";

library LayerZeroLib {
    function sendCrossChainMessage(
        address sender,
        ILayerZeroEndpointV2 endpoint,
        uint32 remoteEid,
        bytes32 trustedPeer,
        address tokenIn,
        address tokenOut,
        uint256 minimalAmountOut, // amount out not this network
        bytes calldata extraData
    )
        internal
        returns (address dstAddress)
    {
        bytes memory message;
        {
            uint256 nonce;
            unchecked {
                nonce = StorageLibrary.getLayerZeroFacetStorage().nonce[remoteEid]++;
            }

            dstAddress = calculateDstAddress({
                sender: sender,
                srcChainId: block.chainid,
                nonce: nonce,
                trustedPeer: trustedPeer,
                extraData: extraData
            });

            message =
                abi.encode(dstAddress, sender, nonce, block.chainid, tokenIn, tokenOut, minimalAmountOut, extraData);
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

    function calculateDstAddress(
        address sender,
        uint256 srcChainId,
        uint256 nonce,
        bytes32 trustedPeer,
        bytes calldata extraData
    )
        internal
        pure
        returns (address dstAddress)
    {
        bytes memory bytecode = abi.encodePacked(
            hex"608160113439333d60010152608134f3fe7f00000000000000000000000000000000000000000000000000000000000000003381146029575b005b3680600014607057602014603c575b6027565b60006044601c8280948135906370a0823183523060205260206040602486855afa5063a9059cbb83526020525af150386038565b5060008080809347905af15038603856",
            extraData
        );

        assembly ("memory-safe") {
            mstore(0, sender)
            mstore(32, add(shl(32, nonce), srcChainId))

            let salt := keccak256(0, 64)

            mstore(0, add(shl(248, 0xff), shl(88, trustedPeer)))
            mstore(21, salt)
            mstore(53, keccak256(add(bytecode, 32), mload(bytecode))) // bytecode hash

            dstAddress := and(keccak256(0, 85), ADDRESS_MASK)

            mstore(64, bytecode)
        }
    }

    function getLzReceiveOptions() internal pure returns (bytes memory options) {
        // uint16(3) - type
        // uint8(1) - worker id
        // uint16(17) - payload length
        // uint8(1) - lzReceive type
        // uint128(100000) - gasLimit
        options = hex"000301001101000000000000000000000000000186a0";
    }

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
