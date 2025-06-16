// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { UlnConfig, Origin } from "./ILayerZeroEndpointV2.sol";

/// @title ILayerZeroFacet - LayerZeroFacet Interface
interface ILayerZeroFacet {
    // =========================
    // errors
    // =========================

    /// @dev Thrown when the lengths of input arrays do not match.
    ///      Triggered in `setPeers` and `setGasLimit` if array lengths are unequal.
    error LayerZeroFacet_LengthMismatch();

    /// @dev Thrown when the contract’s native balance is insufficient to cover the messaging fee.
    ///      Triggered in `sendDeposit` if the balance is less than the quoted fee.
    error LayerZeroFacet_FeeNotMet();

    // =========================
    // getters
    // =========================

    /// @notice Retrieves the endpoint ID of the current chain.
    /// @dev Queries the `_endpointV2` contract for its endpoint ID.
    /// @return The endpoint ID of the current chain.
    function eid() external view returns (uint32);

    /// @notice Retrieves the default gas limit for cross-chain messages.
    /// @dev Returns the `defaultGasLimit` from storage.
    /// @return The default gas limit.
    function defaultGasLimit() external view returns (uint128);

    /// @notice Retrieves the trusted peer address for a remote endpoint ID.
    /// @dev Returns the stored peer or `address(this)` if unset, via `_getPeer`.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @return trustedRemote The trusted peer address (bytes32).
    function getPeer(uint32 remoteEid) external view returns (bytes32 trustedRemote);

    /// @notice Retrieves the gas limit for messages to a remote endpoint ID.
    /// @dev Returns the stored gas limit or `defaultGasLimit` if unset, via `_getGasLimit`.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @return gasLimit The gas limit for messages to the remote chain.
    function getGasLimit(uint32 remoteEid) external view returns (uint128 gasLimit);

    /// @notice Retrieves the delegate address for this contract.
    /// @dev Queries the `_endpointV2` contract for the delegate of this contract (`address(this)`).
    /// @return The delegate address.
    function getDelegate() external view returns (address);

    /// @notice Retrieves the ULN configuration for a specific library and remote endpoint ID.
    /// @dev Queries the `_endpointV2` contract for the configuration and decodes it as `UlnConfig`.
    /// @param lib The address of the messaging library.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @return The `UlnConfig` struct for the specified library and endpoint.
    function getUlnConfig(address lib, uint32 remoteEid) external view returns (UlnConfig memory);

    /// @notice Retrieves the native send capacity for a remote endpoint ID.
    /// @dev Queries the send library’s executor configuration to get the native capacity from `dstConfig`.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @return nativeCap The native send capacity for the remote chain.
    function getNativeSendCap(uint32 remoteEid) external view returns (uint128 nativeCap);

    /// @notice Checks if a remote endpoint ID is supported by the LayerZero endpoint.
    /// @dev Queries the `_endpointV2` contract for support status.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @return True if the endpoint ID is supported, false otherwise.
    function isSupportedEid(uint32 remoteEid) external view returns (bool);

    /// @notice Estimates the native fee for sending a cross-chain message with native drop options.
    /// @dev Constructs native drop options via `_createNativeDropOption` and quotes the fee via `_quote`.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @param nativeAmount The amount of native currency to drop on the remote chain.
    /// @param to The recipient address for the native drop.
    /// @return nativeFee The estimated native currency fee for the message.
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

    /// @notice Sends a cross-chain message with a native drop to a remote chain.
    /// @dev Uses `TransientStorageFacetLibrary` to get the sender, constructs native drop options,
    ///      quotes the fee and sends the message via `_endpointV2.send`.
    ///      Reverts with `LayerZeroFacet_FeeNotMet` if the native balance is insufficient.
    /// @param remoteEid The remote chain’s endpoint ID.
    /// @param nativeDrop The amount of native currency to drop on the remote chain.
    /// @param to The recipient address for the native drop (defaults to sender if zero).
    function sendDeposit(uint32 remoteEid, uint128 nativeDrop, address to) external payable;

    // =========================
    // setters
    // =========================

    /// @notice Sets trusted peer addresses for multiple remote endpoint IDs.
    /// @dev Restricted to the owner. Stores peers in the `peers` mapping. Reverts with `LayerZeroFacet_LengthMismatch`
    ///      if array lengths do not match.
    /// @param remoteEids The array of remote chain endpoint IDs.
    /// @param remoteAddresses The array of trusted peer addresses (bytes32).
    function setPeers(uint32[] calldata remoteEids, bytes32[] calldata remoteAddresses) external;

    /// @notice Sets gas limits for messages to multiple remote endpoint IDs.
    /// @dev Restricted to the owner. Stores gas limits in the `gasLimitLookup` mapping.
    ///      Reverts with `LayerZeroFacet_LengthMismatch` if array lengths do not match.
    /// @param remoteEids The array of remote chain endpoint IDs.
    /// @param gasLimits The array of gas limits for messages to each remote chain.
    function setGasLimit(uint32[] calldata remoteEids, uint128[] calldata gasLimits) external;

    /// @notice Sets the default gas limit for cross-chain messages.
    /// @dev Restricted to the owner. Updates the `defaultGasLimit` in storage.
    /// @param newDefaultGasLimit The new default gas limit.
    function setDefaultGasLimit(uint128 newDefaultGasLimit) external;

    /// @notice Sets the delegate address for this contract.
    /// @dev Restricted to the owner. Calls `_endpointV2.setDelegate` to update the delegate.
    /// @param delegate The new delegate address.
    function setDelegate(address delegate) external;

    /// @notice Configures ULN settings for multiple remote endpoint IDs.
    /// @dev Restricted to the owner. Constructs `UlnConfig` structs and calls
    ///      `_endpointV2.setConfig` to apply configurations. Uses a single required DVN.
    /// @param lib The address of the messaging library.
    /// @param confirmations The number of confirmations required for message verification.
    /// @param eids The array of remote chain endpoint IDs.
    /// @param dvn The address of the required DVN (Decentralized Verifier Network).
    function setUlnConfigs(address lib, uint64 confirmations, uint32[] calldata eids, address dvn) external;

    // =========================
    // receive
    // =========================

    /// @notice Returns the next nonce for a given sender and remote endpoint ID.
    /// @dev Always returns 0, indicating no nonce tracking in this implementation.
    /// @return The next nonce (always 0).
    function nextNonce(uint32, bytes32) external pure returns (uint64);

    function allowInitializePath(Origin calldata origin) external view returns (bool);

    /// @notice Handles incoming LayerZero messages.
    /// @dev Currently a no-op, returning immediately without processing.
    function lzReceive(Origin calldata, bytes32, bytes calldata, address, bytes calldata) external pure;
}
