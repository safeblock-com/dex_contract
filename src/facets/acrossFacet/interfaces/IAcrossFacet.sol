// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IAcrossFacet - AcrossFacet interface
interface IAcrossFacet {
    /// @notice Parameters for an Across V3 cross-chain deposit.
    /// @dev Specifies the tokens, amounts, and metadata for bridging tokens to a destination chain.
    struct V3AcrossDepositParams {
        /// @notice The address to receive the tokens on the destination chain.
        address recipient;
        /// @notice The address of the input token to deposit.
        /// @dev Use address(0) for native currency, which is converted to `_wrappedNative`.
        address inputToken;
        /// @notice The address of the output token on the destination chain.
        address outputToken;
        /// @notice The amount of input tokens to deposit.
        uint256 inputAmount;
        /// @notice The percentage of the input amount expected as output, scaled by 1e18.
        /// @dev Used to calculate the minimum output amount as `inputAmount * outputAmountPercent / E18`.
        uint256 outputAmountPercent;
        /// @notice The chain ID of the destination chain.
        uint256 destinationChainId;
        /// @notice The address of the exclusive relayer (if any).
        /// @dev Set to address(0) for no exclusive relayer.
        address exclusiveRelayer;
        /// @notice The timestamp of the quote for the deposit.
        uint32 quoteTimestamp;
        /// @notice The deadline for filling the deposit on the destination chain.
        uint32 fillDeadline;
        /// @notice The deadline for the exclusive relayer’s exclusivity period.
        uint32 exclusivityDeadline;
        /// @notice The optional message to send with the deposit.
        bytes message;
    }

    // =========================
    // events
    // =========================

    /// @dev Emitted when a callback execution fails in `handleV3AcrossMessage`.
    ///      Includes the error message from the failed call.
    /// @param errorMessage The return data from the failed callback execution.
    event CallFailed(bytes errorMessage);

    // =========================
    // errors
    // =========================

    /// @dev Thrown when the caller of `handleV3AcrossMessage` is not the SpokePool.
    ///      Triggered if `msg.sender` does not match `_spokePool`.
    error AcrossFacet_NotSpokePool();

    // =========================
    // getters
    // =========================

    /// @notice Retrieves the address of the Across V3 SpokePool contract.
    /// @dev Returns the immutable `_spokePool` address.
    /// @return The address of the SpokePool contract.
    function spokePool() external view returns (address);

    // =========================
    // main logic
    // =========================

    /// @notice Initiates a cross-chain token deposit via the Across V3 protocol.
    /// @dev Transfers tokens from the sender (or uses pre-transferred tokens), approves the SpokePool, and calls `depositV3` on the SpokePool.
    ///      Supports native currency deposits by using `_wrappedNative`.
    ///      Uses assembly for the low-level call to `depositV3`.
    /// @param acrossDepositParams The parameters for the cross-chain deposit.
    function sendAcrossDepositV3(IAcrossFacet.V3AcrossDepositParams calldata acrossDepositParams) external;

    /// @notice Handles incoming Across V3 messages with optional callbacks.
    /// @dev Validates the caller as the SpokePool, records the token amount in transient storage, and executes a callback from the message payload.
    ///      If the callback fails, emits `CallFailed` and transfers tokens to the fallback address.
    /// @param tokenSent The address of the token received.
    /// @param amount The amount of tokens received.
    /// @param relayer The relayer address (ignored, provided for interface compatibility).
    /// @param message The message payload containing the fallback address and callback data.
    function handleV3AcrossMessage(address tokenSent, uint256 amount, address relayer, bytes memory message) external;
}
