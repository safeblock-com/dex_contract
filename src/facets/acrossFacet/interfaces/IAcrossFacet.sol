// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IAcrossFacet - AcrossFacet interface
/// @notice Interface for the AcrossFacet contract for cross-chain token bridging
/// @dev This interface defines the functions and structures for interacting with the Across V3 protocol
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
        /// @notice The deadline for the exclusive relayer's exclusivity period.
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
    // getters
    // =========================

    /// @notice Returns the address of the Across V3 SpokePool contract
    /// @return The address of the Across V3 SpokePool contract
    function spokePool() external view returns (address);

    // =========================
    // main logic
    // =========================

    /// @notice Sends a cross-chain deposit via Across V3 protocol
    /// @dev Deposits tokens for cross-chain transfer and handles the callback mechanism
    /// @param acrossDepositParams The deposit parameters for the cross-chain transfer
    /// @return tokensAndAmounts Array of token addresses and amounts used in the transaction
    function sendAcrossDepositV3(IAcrossFacet.V3AcrossDepositParams calldata acrossDepositParams)
        external
        returns (bytes32[] memory tokensAndAmounts);

    /// @notice Handles incoming messages from Across V3 protocol
    /// @dev Processes messages received from the Across V3 SpokePool contract
    /// @param tokenSent The token that was sent across chains
    /// @param amount The amount of tokens sent
    /// @param message The message data containing fallback address and payload
    function handleV3AcrossMessage(address tokenSent, uint256 amount, address relayer, bytes memory message) external;
}
