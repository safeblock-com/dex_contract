// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IStargateFacet - StargateFacet interface
/// @notice Interface for the Stargate facet functionality
/// @dev This interface provides functions for interacting with the Stargate protocol for cross-chain transfers
interface IStargateFacet {
    // =========================
    // events
    // =========================

    /// @notice Emitted when a cross-chain callback execution fails
    /// @dev Emitted when a cross-chain callback execution fails.
    ///      Includes the error message from the failed call, used in `_sendCallback`.
    /// @param errorMessage The return data from the failed callback execution.
    event CallFailed(bytes errorMessage);

    // =========================
    // errors
    // =========================

    /// @dev Thrown when `lzCompose` is called by an address other than the configured LayerZero endpoint.
    error StargateFacet_NotLZEndpoint();

    /// @dev Thrown when attempting to use Stargate with an unsupported native asset.
    /// @dev Stargate supports only ERC20 tokens; native tokens are not allowed.
    error StargateFacet_UnsupportedAsset();

    // =========================
    // getters
    // =========================

    /// @notice Retrieves the address of the LayerZero V2 endpoint contract
    /// @dev Returns the immutable `_lzEndpointV2` address.
    /// @return The address of the LayerZero V2 endpoint contract.
    function lzEndpoint() external view returns (address);

    // =========================
    // quoter
    // =========================

    /// @notice Quotes the native fee and destination amount for a cross-chain token transfer
    /// @dev Constructs a `SendParam` struct and queries the Stargate pool for the fee and minimum output amount
    ///      using `quoteOFT` and `quoteSend`.
    /// @param poolAddress The address of the Stargate pool contract.
    /// @param dstEid The destination chain's LayerZero endpoint ID.
    /// @param amountLD The amount of tokens to send (in local decimals).
    /// @param receiver The recipient address on the destination chain.
    /// @param composeMsg The optional compose message for cross-chain execution.
    /// @param composeGasLimit The gas limit for the compose message execution.
    /// @return valueToSend The native currency fee required for the transfer.
    /// @return dstAmount The minimum amount of tokens received on the destination chain.
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
        returns (uint256 valueToSend, uint256 dstAmount);

    // =========================
    // send
    // =========================

    /// @notice Sends tokens across chains via the Stargate protocol
    /// @dev Transfers tokens from the sender (or uses pre-transferred tokens), applies protocol fees,
    ///      approves the Stargate pool, and initiates the cross-chain transfer.
    ///      Reverts with `StargateFacet_UnsupportedAsset` for native tokens or `StargateFacet_InvalidNativeBalance`
    ///      for insufficient native balance.
    /// @param poolAddress The address of the Stargate pool contract.
    /// @param dstEid The destination chain's LayerZero endpoint ID.
    /// @param receiver The recipient address on the destination chain.
    /// @param composeGasLimit The gas limit for the compose message execution.
    /// @param composeMsg The optional compose message for cross-chain execution.
    /// @return tokensAndAmounts Array of token and amount pairs
    function sendStargateV2(
        address poolAddress,
        uint32 dstEid,
        address receiver,
        uint128 composeGasLimit,
        bytes memory composeMsg
    )
        external
        returns (bytes32[] memory tokensAndAmounts);

    /// @notice Sends tokens across chains via the Stargate protocol
    /// @dev Transfers tokens from the sender (or uses pre-transferred tokens), applies protocol fees,
    ///      approves the Stargate pool, and initiates the cross-chain transfer.
    /// @param poolAddress The address of the Stargate pool contract.
    /// @param dstEid The destination chain's LayerZero endpoint ID.
    /// @param receiver The recipient address on the destination chain.
    /// @param extraData The optional extraData for the message.
    /// @return tokensAndAmounts Array of token and amount pairs
    function sendStargate(
        address poolAddress,
        uint32 dstEid,
        address receiver,
        address tokenOut,
        bytes calldata extraData
    )
        external
        returns (bytes32[] memory tokensAndAmounts);
}
