// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IFeeContract - FeeContract interface
interface IFeeContract {
    // =========================
    // errors
    // =========================

    /// @dev Throws if `fee` is invalid
    error FeeContract_InvalidFeeValue();

    /// @dev Throws if `sender` is not the router
    error FeeContract_InvalidSender(address sender);

    // =========================
    // getters
    // =========================

    /// @notice Returns router address
    function router() external view returns (address);

    /// @notice Returns the balance of the `owner` for the `token`
    function profit(address token) external view returns (uint256 balance);

    // =========================
    // admin logic
    // =========================

    /// @notice Sets new router
    function setRouter(address newRouter) external;

    // =========================
    // fees logic
    // =========================

    /// @notice Collects protocol fees
    function collectProtocolFees(address token, address recipient, uint256 amount) external;
}
