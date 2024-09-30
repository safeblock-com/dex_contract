// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { UlnConfig, Origin } from "../stargate/ILayerZeroEndpointV2.sol";

/// @title ILayerZeroFacet - LayerZeroFacet Interface
interface ILayerZeroFacet {
    // =========================
    // errors
    // =========================

    /// @notice Throws when passed array length does not match
    error LayerZeroFacet_LengthMismatch();

    /// @notice Throws when native amount on contract does not gte fee amount
    error LayerZeroFacet_FeeNotMet();

    // =========================
    // getters
    // =========================

    /// @notice Returns eid for the current chain.
    function eid() external view returns (uint32);

    /// @notice Returns default gas limit in the protocol.
    function defaultGasLimit() external view returns (uint128);

    /// @notice Returns address in the bytes32 representation which refers to the passed eid.
    function getPeer(uint32 remoteEid) external view returns (bytes32 trustedRemote);

    /// @notice Returns gasLimit which refers to the passed eid.
    function getGasLimit(uint32 remoteEid) external view returns (uint128 gasLimit);

    /// @notice Returns delegate of this contract in LayerZeroV2 endpoint.
    function getDelegate() external view returns (address);

    /// @notice Returns ULN config in LayerZero protocol from passed `lib`.
    function getUlnConfig(address lib, uint32 remoteEid) external view returns (UlnConfig memory);

    /// @notice Returns native send cap in LayerZero protocol from passed `remoteEid`.
    function getNativeSendCap(uint32 remoteEid) external view returns (uint128 nativeCap);

    /// @notice Returns true if passed eid is supported.
    function isSupportedEid(uint32 remoteEid) external view returns (bool);

    /// @notice Returns fee estimate in LayerZero protocol for passed `remoteEid` and `nativeAmount`.
    function estimateFee(
        uint32 remoteEid,
        uint128 nativeAmount,
        address to
    )
        external
        view
        returns (uint256 nativeFee);

    // =========================
    // main
    // =========================

    /// @notice Sends native deposit to LayerZero protocol.
    function sendDeposit(uint32 remoteEid, uint128 nativeDrop, address to) external payable;

    // =========================
    // setters
    // =========================

    /// @notice Sets peers for passed remoteEids.
    function setPeers(uint32[] calldata remoteEids, bytes32[] calldata remoteAddresses) external;

    /// @notice Sets gasLimit for passed remoteEids.
    function setGasLimit(uint32[] calldata remoteEids, uint128[] calldata gasLimits) external;

    /// @notice Sets new defaultGasLimit.
    function setDefaultGasLimit(uint128 defaultGasLimit_) external;

    /// @notice Sets new delegate in LayerZeroV2 enpoint.
    function setDelegate(address delegate) external;

    /// @notice Sets ULN config for passed eids.
    function setUlnConfigs(address lib, uint64 confirmations, uint32[] calldata eids, address dvn) external;

    // =========================
    // receive
    // =========================

    /// @notice Mock methods for lzReceive work.
    function nextNonce(uint32, bytes32) external pure returns (uint64);

    function allowInitializePath(Origin calldata origin) external view returns (bool);

    /// @notice Just return cause native airdrop not need this method.
    function lzReceive(Origin calldata, bytes32, bytes calldata, address, bytes calldata) external pure;
}
