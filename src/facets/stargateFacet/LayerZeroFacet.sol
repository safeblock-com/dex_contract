// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { BaseOwnableFacet } from "../BaseOwnableFacet.sol";

import { Utils } from "../../libraries/Utils.sol";
import { StorageLibrary, LayerZeroFacetStorage } from "../../libraries/StorageLibrary.sol";
import { TransientStorageLibrary } from "../../libraries/TransientStorageLibrary.sol";
import { Utils } from "../../libraries/Utils.sol";

import {
    ILayerZeroEndpointV2,
    UlnConfig,
    Origin,
    MessagingFee,
    MessagingParams
} from "./interfaces/ILayerZeroEndpointV2.sol";
import { IMessageLibManager } from "./interfaces/IMessageLibManager.sol";
import { ISendLib } from "./interfaces/ISendLib.sol";

import { ILayerZeroFacet } from "./interfaces/ILayerZeroFacet.sol";

/// @title LayerZeroFacet
/// @notice A facet for cross-chain messaging via the LayerZero V2 protocol in a diamond-like proxy contract.
/// @dev Supports sending native drop messages, configuring trusted peers, gas limits, and ULN configurations.
///      This facet is part of the diamond proxy pattern and provides functionality for cross-chain messaging
///      using the LayerZero V2 protocol. It integrates with the EntryPoint contract to route calls appropriately.
contract LayerZeroFacet is BaseOwnableFacet, ILayerZeroFacet {
    // =========================
    // storage
    // =========================

    /// @dev The address of the LayerZero V2 endpoint contract.
    ///      Immutable, set during construction. Used for sending messages and querying configurations.
    ILayerZeroEndpointV2 internal immutable _endpointV2;

    // =========================
    // storage
    // =========================

    // =========================
    // constructor
    // =========================

    /// @notice Initializes the LayerZeroFacet with the LayerZero V2 endpoint address.
    /// @dev Sets the immutable `_endpointV2` address and initializes ownership via `Ownable`.
    /// @param endpointV2 The address of the LayerZero V2 endpoint contract.
    constructor(address endpointV2) {
        _endpointV2 = ILayerZeroEndpointV2(endpointV2);
    }
    // =========================
    // getters
    // =========================

    /// @inheritdoc ILayerZeroFacet
    function eid() external view returns (uint32) {
        return _endpointV2.eid();
    }

    /// @inheritdoc ILayerZeroFacet
    function defaultGasLimit() external view returns (uint128) {
        return StorageLibrary.getLayerZeroFacetStorage().defaultGasLimit;
    }

    /// @inheritdoc ILayerZeroFacet
    function getPeer(uint32 remoteEid) external view returns (bytes32 trustedRemote) {
        return _getPeer(remoteEid);
    }

    /// @inheritdoc ILayerZeroFacet
    function getGasLimit(uint32 remoteEid) external view returns (uint128 gasLimit) {
        gasLimit = _getGasLimit(remoteEid);
    }

    /// @inheritdoc ILayerZeroFacet
    function getDelegate() external view returns (address) {
        return _endpointV2.delegates({ oapp: address(this) });
    }

    /// @inheritdoc ILayerZeroFacet
    function getUlnConfig(address lib, uint32 remoteEid) external view returns (UlnConfig memory) {
        bytes memory config = _endpointV2.getConfig({ oapp: address(this), lib: lib, eid: remoteEid, configType: 2 });

        return abi.decode(config, (UlnConfig));
    }

    /// @inheritdoc ILayerZeroFacet
    function getNativeSendCap(uint32 remoteEid) external view returns (uint128 nativeCap) {
        (,,, nativeCap) = ISendLib(
            ISendLib(_endpointV2.getSendLibrary({ sender: address(this), dstEid: remoteEid })).getExecutorConfig({
                oapp: address(this),
                remoteEid: remoteEid
            }).executor
        ).dstConfig({ dstEid: remoteEid });
    }

    /// @inheritdoc ILayerZeroFacet
    function isSupportedEid(uint32 remoteEid) external view returns (bool) {
        return _endpointV2.isSupportedEid({ eid: remoteEid });
    }

    /// @inheritdoc ILayerZeroFacet
    function estimateFee(
        uint32 remoteEid,
        uint128 nativeAmount,
        address to
    )
        external
        view
        returns (uint256 nativeFee)
    {
        unchecked {
            return _quote(remoteEid, _createNativeDropOption(remoteEid, nativeAmount, to));
        }
    }

    // =========================
    // admin methods
    // =========================

    /// @inheritdoc ILayerZeroFacet
    function setPeers(uint32[] calldata remoteEids, bytes32[] calldata remoteAddresses) external onlyOwner {
        uint256 length = remoteEids.length;
        Utils.expectEqual({ left: length, right: remoteAddresses.length });

        LayerZeroFacetStorage storage s = StorageLibrary.getLayerZeroFacetStorage();

        for (uint256 i; i < length;) {
            s.peers[remoteEids[i]] = remoteAddresses[i];

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ILayerZeroFacet
    function setGasLimit(uint32[] calldata remoteEids, uint128[] calldata gasLimits) external onlyOwner {
        Utils.expectEqual({ left: remoteEids.length, right: gasLimits.length });

        LayerZeroFacetStorage storage s = StorageLibrary.getLayerZeroFacetStorage();

        for (uint256 i; i < remoteEids.length;) {
            s.gasLimitLookup[remoteEids[i]] = gasLimits[i];

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ILayerZeroFacet
    function setDefaultGasLimit(uint128 newDefaultGasLimit) external onlyOwner {
        StorageLibrary.getLayerZeroFacetStorage().defaultGasLimit = newDefaultGasLimit;
    }

    /// @inheritdoc ILayerZeroFacet
    function setDelegate(address delegate) external onlyOwner {
        _endpointV2.setDelegate({ delegate: delegate });
    }

    /// @inheritdoc ILayerZeroFacet
    function setUlnConfigs(address lib, uint64 confirmations, uint32[] calldata eids, address dvn) external onlyOwner {
        uint256 length = eids.length;

        IMessageLibManager.SetConfigParam[] memory configs = new IMessageLibManager.SetConfigParam[](length);

        for (uint256 i; i < length; i++) {
            address[] memory opt = new address[](0);
            address[] memory req = new address[](1);
            req[0] = dvn;

            bytes memory config = abi.encode(
                UlnConfig({
                    confirmations: confirmations,
                    requiredDVNCount: uint8(1),
                    optionalDVNCount: 0,
                    optionalDVNThreshold: 0,
                    requiredDVNs: req,
                    optionalDVNs: opt
                })
            );
            configs[i] = IMessageLibManager.SetConfigParam({ eid: eids[i], configType: 2, config: config });

            unchecked {
                ++i;
            }
        }

        IMessageLibManager(address(_endpointV2)).setConfig({ oapp: address(this), lib: lib, params: configs });
    }

    // =========================
    // main
    // =========================

    /// @inheritdoc ILayerZeroFacet
    function sendDeposit(
        uint32 remoteEid,
        uint128 nativeDrop,
        address to
    )
        external
        payable
        returns (bytes32[] memory)
    {
        address sender = TransientStorageLibrary.getSenderAddress();

        bytes memory options = _createNativeDropOption(remoteEid, nativeDrop, to > address(0) ? to : sender);

        uint256 fee = _quote(remoteEid, options);

        Utils.compareAmounts({ greaterValue: address(this).balance, lowerValue: fee });

        _endpointV2.send{ value: fee }({
            params: MessagingParams({
                dstEid: remoteEid,
                receiver: _getPeer(remoteEid),
                message: bytes(""),
                options: options,
                payInLzToken: false
            }),
            refundAddress: sender
        });

        return Utils.decodeTokensAndAmountsArray();
    }

    // =========================
    // receive
    // =========================

    /// @inheritdoc ILayerZeroFacet
    function nextNonce(uint32, bytes32) external pure returns (uint64) {
        return 0;
    }

    /// @inheritdoc ILayerZeroFacet
    function allowInitializePath(Origin calldata origin) external view returns (bool) {
        return _getPeer(origin.srcEid) == origin.sender;
    }

    /// @inheritdoc ILayerZeroFacet
    function lzReceive(Origin calldata, bytes32, bytes calldata, address, bytes calldata) external pure {
        return;
    }

    // =========================
    // internal
    // =========================

    /// @dev Constructs native drop options for a cross-chain message.
    ///      Encodes the gas limit, native amount, and recipient address into a LayerZero options format,
    ///      including `lzReceive` and `nativeDrop` types.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @param nativeAmount The amount of native currency to drop.
    /// @param to The recipient address for the native drop.
    /// @return The encoded options bytes for the LayerZero message.
    function _createNativeDropOption(
        uint32 remoteEid,
        uint128 nativeAmount,
        address to
    )
        internal
        view
        returns (bytes memory)
    {
        bytes32 _to;

        assembly {
            _to := to
        }

        return abi.encodePacked(
            abi.encodePacked(
                // uint16(3) - type
                // uint8(1) - worker id
                // uint16(17) - payload length
                // uint8(1) - lzReceive type
                uint48(0x00301001101),
                _getGasLimit(remoteEid)
            ),
            // uint8(1) - worker id
            // uint16(49) - payload length
            // uint8(2) - native drop type
            uint32(0x01003102),
            nativeAmount,
            _to
        );
    }

    /// @dev Quotes the native fee for a cross-chain message.
    ///      Constructs a `MessagingParams` struct with the provided options and queries `_endpointV2.quote` for the fee.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @param options The encoded options for the message (e.g., native drop).
    /// @return nativeFee The estimated native currency fee for the message.
    function _quote(uint32 remoteEid, bytes memory options) internal view returns (uint256 nativeFee) {
        MessagingFee memory fee = _endpointV2.quote({
            params: MessagingParams({
                dstEid: remoteEid,
                receiver: _getPeer(remoteEid),
                message: bytes(""),
                options: options,
                payInLzToken: false
            }),
            sender: address(this)
        });

        return fee.nativeFee;
    }

    /// @dev Retrieves the trusted peer address for a remote endpoint ID.
    ///      Returns the stored peer from the `peers` mapping or `address(this)` if unset.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @return trustedRemote The trusted peer address (bytes32).
    function _getPeer(uint32 remoteEid) internal view returns (bytes32 trustedRemote) {
        trustedRemote = StorageLibrary.getLayerZeroFacetStorage().peers[remoteEid];
        if (trustedRemote == 0) {
            assembly {
                trustedRemote := address()
            }
        }
    }

    /// @dev Retrieves the gas limit for messages to a remote endpoint ID.
    ///      Returns the stored gas limit from `gasLimitLookup` or `defaultGasLimit` if unset.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @return gasLimit The gas limit for messages to the remote chain.
    function _getGasLimit(uint32 remoteEid) internal view returns (uint128 gasLimit) {
        LayerZeroFacetStorage storage s = StorageLibrary.getLayerZeroFacetStorage();

        gasLimit = s.gasLimitLookup[remoteEid];
        if (gasLimit == 0) {
            gasLimit = s.defaultGasLimit;
        }
    }
}
