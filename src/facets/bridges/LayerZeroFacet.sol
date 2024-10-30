// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from "../../external/Ownable.sol";

import {
    ILayerZeroEndpointV2, UlnConfig, Origin, MessagingFee, MessagingParams
} from "./stargate/ILayerZeroEndpointV2.sol";
import { IMessageLibManager } from "./stargate/IMessageLibManager.sol";
import { ISendLib } from "./stargate/ISendLib.sol";

import { TransientStorageFacetLibrary } from "../../libraries/TransientStorageFacetLibrary.sol";

import { ILayerZeroFacet } from "./interfaces/ILayerZeroFacet.sol";

/// @title LayerZeroFacet
contract LayerZeroFacet is Ownable, ILayerZeroFacet {
    // =========================
    // immutable storage
    // =========================

    /// @dev LayerZeroV2 endpoint
    ILayerZeroEndpointV2 internal immutable _endpointV2;

    // =========================
    // storage
    // =========================

    struct LayerZeroFacetStorage {
        /// @dev trusted peers, default - address(this)
        mapping(uint32 eid => bytes32 peer) peers;
        /// @dev gas limit lookup
        mapping(uint32 eid => uint128 gasLimit) gasLimitLookup;
        /// @dev default gas limit
        uint128 defaultGasLimit;
    }

    /// @dev Storage position for the layerZero facet, to avoid collisions in storage.
    /// @dev Uses the "magic" constant to find a unique storage slot.
    // keccak256("layerZero.storage")
    bytes32 private constant LAYERZERO_FACET_STORAGE =
        0x7f8156d470b4ca2c59b150cce6693dce9d231528b9e476a0fbfb17f10e0dab09;

    /// @dev Returns the storage slot for the LayerZeroFacet.
    /// @dev This function utilizes inline assembly to directly access the desired storage position.
    ///
    /// @return s The storage slot pointer for the LayerZeroFacet.
    function _getLocalStorage() internal pure returns (LayerZeroFacetStorage storage s) {
        assembly ("memory-safe") {
            s.slot := LAYERZERO_FACET_STORAGE
        }
    }

    // =========================
    // constructor
    // =========================

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
        return _getLocalStorage().defaultGasLimit;
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
        if (length != remoteAddresses.length) {
            revert ILayerZeroFacet.LayerZeroFacet_LengthMismatch();
        }

        LayerZeroFacetStorage storage s = _getLocalStorage();

        for (uint256 i; i < length;) {
            s.peers[remoteEids[i]] = remoteAddresses[i];

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ILayerZeroFacet
    function setGasLimit(uint32[] calldata remoteEids, uint128[] calldata gasLimits) external onlyOwner {
        if (remoteEids.length != gasLimits.length) {
            revert ILayerZeroFacet.LayerZeroFacet_LengthMismatch();
        }

        LayerZeroFacetStorage storage s = _getLocalStorage();

        for (uint256 i; i < remoteEids.length;) {
            s.gasLimitLookup[remoteEids[i]] = gasLimits[i];

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ILayerZeroFacet
    function setDefaultGasLimit(uint128 newDefaultGasLimit) external onlyOwner {
        _getLocalStorage().defaultGasLimit = newDefaultGasLimit;
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
    function sendDeposit(uint32 remoteEid, uint128 nativeDrop, address to) external payable {
        address sender = TransientStorageFacetLibrary.getSenderAddress();

        bytes memory options = _createNativeDropOption(remoteEid, nativeDrop, to > address(0) ? to : sender);

        uint256 fee = _quote(remoteEid, options);

        if (fee > address(this).balance) {
            revert ILayerZeroFacet.LayerZeroFacet_FeeNotMet();
        }

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

    /// @dev Creates native drop options for passed `nativeAmount` and `to`.
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

    /// @dev Calculates fee in native token for passed options.
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

    /// @dev Hepler method for get peer for passed remoteEid.
    function _getPeer(uint32 remoteEid) internal view returns (bytes32 trustedRemote) {
        trustedRemote = _getLocalStorage().peers[remoteEid];
        if (trustedRemote == 0) {
            assembly {
                trustedRemote := address()
            }
        }
    }

    /// @dev Hepler method for get gasLimit for passed remoteEid.
    function _getGasLimit(uint32 remoteEid) internal view returns (uint128 gasLimit) {
        LayerZeroFacetStorage storage s = _getLocalStorage();

        gasLimit = s.gasLimitLookup[remoteEid];
        if (gasLimit == 0) {
            gasLimit = s.defaultGasLimit;
        }
    }
}
