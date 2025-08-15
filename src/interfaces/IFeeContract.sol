// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IFeeContract - FeeContract interface
/// @notice Interface for the FeeContract functionality
/// @dev This interface defines the functions for handling fee collection and distribution in the DEX protocol
interface IFeeContract {
    // =========================
    // errors
    // =========================

    /// @dev Throws if `fee` is invalid
    /// @notice Thrown when an invalid fee value is provided
    error FeeContract_InvalidFeeValue();

    /// @dev Throws if `sender` is not the router
    /// @notice Thrown when a function is called by an address other than the authorized router
    /// @param sender The address that attempted to call the function
    error FeeContract_InvalidSender(address sender);

    // =========================
    // getters
    // =========================

    /// @notice Returns router address
    /// @dev Getter function to retrieve the currently set router address
    /// @return The address of the router contract
    function router() external view returns (address);

    /// @notice Returns the balance of a specific token held by this contract
    /// @dev Uses TransferHelper to safely get the balance of the specified token
    /// @param token The address of the token to check the balance for
    /// @return balance The balance of the specified token
    function profit(address token) external view returns (uint256 balance);

    // =========================
    // admin logic
    // =========================

    /// @notice Sets a new router address
    /// @dev Only callable by the owner. Updates the router address used for fee calculations.
    /// @param newRouter The new router address to set
    function setRouter(address newRouter) external;

    // =========================
    // fees logic
    // =========================

    /// @notice Allows the owner to collect protocol fees
    /// @dev Transfers a specified amount of tokens to a recipient, up to the contract's balance
    /// @param token The address of the token to transfer
    /// @param recipient The address to receive the tokens
    /// @param amount The amount of tokens to transfer
    function collectProtocolFees(address token, address recipient, uint256 amount) external;
}
